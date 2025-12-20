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
            messages[0] = ChatMessage(content: welcomeContent, isUser: false)
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
            isUser: false
        )
        messages.append(welcomeMessage)
    }

    func sendMessage() {
        let input = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !input.isEmpty else { return }
        guard !isLoading else { return }

        // Add user message
        let userMessage = ChatMessage(content: input, isUser: true)
        messages.append(userMessage)

        // Clear input
        currentInput = ""

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
                    _ = try await supabaseManager.saveMessage(
                        conversationId: conversationId,
                        content: input,
                        isUser: true
                    )
                }
                
                let quote = try await kimiService.getQuote(for: input)

                // Stop loading FIRST, then add message (prevents flash)
                isLoading = false
                
                // Add bot response
                let botMessage = ChatMessage(content: quote, isUser: false, shouldAnimate: true)
                messages.append(botMessage)
                
                // Save bot message to database (in background, doesn't affect UI)
                if let conversationId = currentConversation?.id {
                    _ = try await supabaseManager.saveMessage(
                        conversationId: conversationId,
                        content: quote,
                        isUser: false
                    )
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

    func clearChat() {
        messages.removeAll()
        currentConversation = nil  // Reset conversation for new chat
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
        } catch {
            errorMessage = "Failed to load conversation: \(error.localizedDescription)"
        }
    }
}
