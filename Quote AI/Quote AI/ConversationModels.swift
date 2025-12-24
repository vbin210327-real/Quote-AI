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
        return ChatMessage(id: id, content: content, isUser: isUser)
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

// MARK: - User Profile (Database Model)
struct UserProfile: Codable {
    let id: UUID?
    let userId: String
    var name: String?
    var gender: String?
    var profileImageUrl: String?
    var birthYear: Int?
    var quoteTone: String?
    var userFocus: String?
    var userBarrier: String?
    var energyDrain: String?
    var mentalEnergy: Double?
    var chatBackground: String?
    var language: String?
    var hasCompletedOnboarding: Bool?
    var updatedAt: Date?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case gender
        case profileImageUrl = "profile_image_url"
        case birthYear = "birth_year"
        case quoteTone = "quote_tone"
        case userFocus = "user_focus"
        case userBarrier = "user_barrier"
        case energyDrain = "energy_drain"
        case mentalEnergy = "mental_energy"
        case chatBackground = "chat_background"
        case language
        case hasCompletedOnboarding = "has_completed_onboarding"
        case updatedAt = "updated_at"
        case createdAt = "created_at"
    }
}

struct UpsertUserProfileRequest: Codable {
    let userId: String
    let name: String?
    let gender: String?
    let profileImageUrl: String?
    let birthYear: Int?
    let quoteTone: String?
    let userFocus: String?
    let userBarrier: String?
    let energyDrain: String?
    let mentalEnergy: Double?
    let chatBackground: String?
    let language: String?
    let hasCompletedOnboarding: Bool?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case gender
        case profileImageUrl = "profile_image_url"
        case birthYear = "birth_year"
        case quoteTone = "quote_tone"
        case userFocus = "user_focus"
        case userBarrier = "user_barrier"
        case energyDrain = "energy_drain"
        case mentalEnergy = "mental_energy"
        case chatBackground = "chat_background"
        case language
        case hasCompletedOnboarding = "has_completed_onboarding"
        case updatedAt = "updated_at"
    }
}

// MARK: - Cloud Saved Quote (Database Model)
struct CloudSavedQuote: Identifiable, Codable {
    let id: UUID
    let userId: String
    let content: String
    let savedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case content
        case savedAt = "saved_at"
    }
}

struct SaveQuoteRequest: Codable {
    let userId: String
    let content: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case content
    }
}
