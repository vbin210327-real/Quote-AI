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

    private let kimiService = KimiService.shared
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

        // Set loading state
        isLoading = true

        // Get quote from API
        Task {
            do {
                let quote = try await kimiService.getQuote(for: input)

                // Add bot response
                let botMessage = ChatMessage(content: quote, isUser: false)
                messages.append(botMessage)

            } catch {
                // Handle error
                errorMessage = error.localizedDescription

                let errorBotMessage = ChatMessage(
                    content: localization.string(for: "chat.errorMessage"),
                    isUser: false
                )
                messages.append(errorBotMessage)
            }

            isLoading = false
        }
    }

    func clearChat() {
        messages.removeAll()
        // Re-add personalized welcome message
        addWelcomeMessage()
    }
}
