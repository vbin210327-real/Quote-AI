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

    init() {
        // Add welcome message
        let welcomeMessage = ChatMessage(
            content: "Welcome! Share what's on your mind, and I'll respond with a quote to inspire and motivate you.",
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
                    content: "Sorry, I encountered an error. Please try again.",
                    isUser: false
                )
                messages.append(errorBotMessage)
            }

            isLoading = false
        }
    }

    func clearChat() {
        messages.removeAll()
        // Re-add welcome message
        let welcomeMessage = ChatMessage(
            content: "Welcome! Share what's on your mind, and I'll respond with a quote to inspire and motivate you.",
            isUser: false
        )
        messages.append(welcomeMessage)
    }
}
