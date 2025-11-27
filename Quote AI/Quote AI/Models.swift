//
//  Models.swift
//  Quote AI
//
//  Data models for the app
//

import Foundation

// MARK: - Chat Message
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date

    init(content: String, isUser: Bool) {
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
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

struct KimiMessage: Codable {
    let role: String
    let content: String
}

// MARK: - Kimi API Response Models
struct KimiResponse: Codable {
    let choices: [KimiChoice]
    let usage: KimiUsage?
}

struct KimiChoice: Codable {
    let message: KimiMessage
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
