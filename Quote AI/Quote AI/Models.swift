//
//  Models.swift
//  Quote AI
//
//  Data models for the app
//

import Foundation

// MARK: - Chat Message
struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    let shouldAnimate: Bool
    let isWelcome: Bool

    init(id: UUID = UUID(), content: String, isUser: Bool, shouldAnimate: Bool = false, isWelcome: Bool = false) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
        self.shouldAnimate = shouldAnimate
        self.isWelcome = isWelcome
    }
}

// MARK: - Kimi API Request Models
struct KimiRequest: Codable {
    let model: String
    let messages: [KimiMessage]
    let temperature: Double
    let maxTokens: Int

    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

// For API requests (simple structure)
struct KimiMessage: Codable {
    let role: String
    let content: String
}

// For API responses (includes reasoning_content for thinking models)
struct KimiResponseMessage: Codable {
    let role: String
    let content: String?
    let reasoningContent: String?

    enum CodingKeys: String, CodingKey {
        case role, content
        case reasoningContent = "reasoning_content"
    }
}

// MARK: - Kimi API Response Models
struct KimiResponse: Codable {
    let choices: [KimiChoice]
    let usage: KimiUsage?
}

struct KimiChoice: Codable {
    let message: KimiResponseMessage
    let finishReason: String?

    enum CodingKeys: String, CodingKey {
        case message
        case finishReason = "finish_reason"
    }
}

struct KimiUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}
