//
//  ConversationModels.swift
//  Quote AI
//
//  Database models for storing conversations
//

import Foundation

// MARK: - Conversation (Database Model)
struct Conversation: Identifiable, Codable {
    let id: UUID
    let userId: String
    let title: String  // Auto-generated from first user message
    let createdAt: Date
    let updatedAt: Date
    let snippet: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case snippet = "match_snippet"
    }
}

// MARK: - Message (Database Model)
struct StoredMessage: Identifiable, Codable {
    let id: UUID
    let conversationId: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case content
        case isUser = "is_user"
        case timestamp
    }
    
    // Convert to ChatMessage for display
    func toChatMessage() -> ChatMessage {
        return ChatMessage(content: content, isUser: isUser)
    }
}

// MARK: - Request/Response Models
struct CreateConversationRequest: Codable {
    let userId: String
    let title: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case title
    }
}

struct SaveMessageRequest: Codable {
    let conversationId: UUID
    let content: String
    let isUser: Bool
    
    enum CodingKeys: String, CodingKey {
        case conversationId = "conversation_id"
        case content
        case isUser = "is_user"
    }
}
