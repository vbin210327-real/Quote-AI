//
//  ChatViewModel.swift
//  Quote AI
//
//  View model for chat functionality
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var currentInput: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentConversation: Conversation?
    @Published var currentTokenCount: Int = 0
    @Published var showTokenWarning: Bool = false
    @Published var isAtTokenLimit: Bool = false
    private var hasShownWarning: Bool = false  // Track if warning was already shown

    let maxTokens: Int = 32000        // ~100+ messages before block
    let warningThreshold: Int = 25600 // 80% - warning shows first

    private let kimiService = KimiService.shared
    private let supabaseManager = SupabaseManager.shared
    private let localization = LocalizationManager.shared
    private var languageObserver: AnyCancellable?

    init() {
        // Add personalized welcome message
        addWelcomeMessage()

        // Observe language changes to update welcome message
        languageObserver = localization.$currentLanguage
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshWelcomeMessage()
            }
    }

    private func refreshWelcomeMessage() {
        // Only update the first message (welcome message) if it exists and is not from user
        if let firstMessage = messages.first, !firstMessage.isUser {
            let userName = UserPreferences.shared.userName
            let welcomeContent: String
            if userName.isEmpty {
                welcomeContent = localization.string(for: "chat.welcomeGeneric")
            } else {
                let template = localization.string(for: "chat.welcomePersonalized")
                welcomeContent = String(format: template, userName)
            }
            messages[0] = ChatMessage(content: welcomeContent, isUser: false, isWelcome: true)
        }
    }

    private func addWelcomeMessage() {
        let userName = UserPreferences.shared.userName
        let welcomeContent: String
        if userName.isEmpty {
            welcomeContent = localization.string(for: "chat.welcomeGeneric")
        } else {
            let template = localization.string(for: "chat.welcomePersonalized")
            welcomeContent = String(format: template, userName)
        }

        let welcomeMessage = ChatMessage(
            content: welcomeContent,
            isUser: false,
            isWelcome: true
        )
        messages.append(welcomeMessage)
    }

    /// Estimate token count for a text string
    private func estimateTokens(_ text: String) -> Int {
        // Rough estimate: ~3 chars per token (balanced for English/Chinese)
        return max(1, text.count / 3)
    }

    /// Update the current token count based on all messages
    private func updateTokenCount() {
        currentTokenCount = messages
            .filter { !$0.isWelcome }
            .reduce(0) { $0 + estimateTokens($1.content) }

        // Check if at limit first
        isAtTokenLimit = currentTokenCount >= maxTokens

        // Hide warning when at limit (block banner takes over)
        if isAtTokenLimit {
            showTokenWarning = false
        } else if currentTokenCount >= warningThreshold && !hasShownWarning {
            // Show warning only once when threshold is first crossed
            showTokenWarning = true
            hasShownWarning = true
        }
    }

    /// Dismiss the warning banner
    func dismissWarning() {
        showTokenWarning = false
    }

    func sendMessage(text: String? = nil, tone: QuoteTone? = nil) {
        let inputToCheck = text ?? currentInput
        let input = inputToCheck.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !input.isEmpty else { return }
        guard !isLoading else { return }

        // Check token limit
        guard !isAtTokenLimit else {
            errorMessage = localization.string(for: "chat.tokenLimitReached")
            return
        }

        // Dismiss warning if showing
        dismissWarning()

        // Add user message
        let userMessage = ChatMessage(content: input, isUser: true)
        messages.append(userMessage)
        updateTokenCount()

        // Clear input only if we used the text field
        if text == nil {
            currentInput = ""
        }

        // Clear previous error
        errorMessage = nil

        // Set loading state with animation
        withAnimation(.easeInOut(duration: 0.2)) {
            isLoading = true
        }

        // Get quote from API
        Task {
            do {
                // Create conversation if this is the first message
                if currentConversation == nil {
                    let conversationTitle = input.prefix(50).description // Use first 50 chars as title
                    currentConversation = try await supabaseManager.createConversation(title: conversationTitle)
                }
                
                // Save user message to database
                if let conversationId = currentConversation?.id {
                    let storedUserMsg = try await supabaseManager.saveMessage(
                        conversationId: conversationId,
                        content: input,
                        isUser: true
                    )
                    // Update local message ID to match DB ID
                    if let index = messages.firstIndex(where: { $0.content == input && $0.isUser && $0.id != storedUserMsg.id }) {
                        messages[index] = storedUserMsg.toChatMessage()
                    }
                }
                
                // Pass conversation history (filter out welcome message)
                let history = messages.filter { !$0.isWelcome }
                let quote = try await kimiService.getQuote(for: input, conversationHistory: history, tone: tone)

                // Stop loading FIRST, then add message (prevents flash)
                isLoading = false
                
                // Add bot response (temporary ID)
                let botMessage = ChatMessage(content: quote, isUser: false, shouldAnimate: true)
                messages.append(botMessage)
                updateTokenCount()

                // Save bot message to database
                if let conversationId = currentConversation?.id {
                    let storedBotMsg = try await supabaseManager.saveMessage(
                        conversationId: conversationId,
                        content: quote,
                        isUser: false
                    )
                    // Update local message ID to match DB ID
                    if let index = messages.firstIndex(where: { $0.content == quote && !$0.isUser && $0.id != storedBotMsg.id }) {
                        messages[index] = storedBotMsg.toChatMessage()
                    }
                }

            } catch {
                // Handle error
                errorMessage = error.localizedDescription

                // Stop loading FIRST
                isLoading = false

                let errorBotMessage = ChatMessage(
                    content: localization.string(for: "chat.errorMessage"),
                    isUser: false
                )
                messages.append(errorBotMessage)
            }
        }
    }

    func regenerateMessage(for message: ChatMessage, tone: QuoteTone? = nil) {
        guard !isLoading else { return }
        guard let messageIndex = messages.firstIndex(where: { $0.id == message.id }) else { return }
        
        var promptIndex: Int?
        var prompt: String?
        
        // Find the preceding user message (the prompt)
        if messageIndex > 0 {
            for index in stride(from: messageIndex - 1, through: 0, by: -1) {
                if messages[index].isUser {
                    prompt = messages[index].content
                    promptIndex = index
                    break
                }
            }
        }
        
        guard let userPrompt = prompt, !userPrompt.isEmpty, let pIndex = promptIndex else { return }
        
        // Capture IDs for deletion
        let aiMessageId = message.id
        let userMessageId = messages[pIndex].id
        
        // Remove both messages from local state immediately with animation
        withAnimation(.easeOut(duration: 0.2)) {
            // Remove higher index first to avoid index shifting problems
            let indicesToRemove = [messageIndex, pIndex].sorted(by: >)
            for index in indicesToRemove {
                messages.remove(at: index)
            }
        }
        
        // Handle deletion and re-sending in a background task
        Task {
            // Delete from database
            do {
                try await supabaseManager.deleteMessage(messageId: aiMessageId)
                try await supabaseManager.deleteMessage(messageId: userMessageId)
            } catch {
                print("Error deleting messages for regeneration: \(error)")
            }
            
            // Resend the original question to generate a new answer at the bottom
            // Using a slight delay to ensure the removal animation finishes or is noticed
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            sendMessage(text: userPrompt, tone: tone)
        }
    }

    func clearChat() {
        messages.removeAll()
        currentConversation = nil  // Reset conversation for new chat
        currentTokenCount = 0
        showTokenWarning = false
        isAtTokenLimit = false
        hasShownWarning = false  // Reset so warning can show again in new chat
        // Re-add personalized welcome message
        addWelcomeMessage()
    }
    
    /// Load an existing conversation from database
    func loadConversation(_ conversation: Conversation) async {
        currentConversation = conversation
        messages.removeAll()

        do {
            let storedMessages = try await supabaseManager.fetchMessages(conversationId: conversation.id)
            messages = storedMessages.map { $0.toChatMessage() }
            updateTokenCount()
        } catch {
            errorMessage = "Failed to load conversation: \(error.localizedDescription)"
        }
    }
}
