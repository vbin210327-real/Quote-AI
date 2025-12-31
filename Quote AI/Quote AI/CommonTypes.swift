//
//  CommonTypes.swift
//  Quote AI
//
//  Shared types between main app and extensions
//

import Foundation

enum QuoteTone: String, CaseIterable, Codable {
    case motivational = "Motivational"
    case naval = "Navalism"
    case philosophical = "Philosophical"
    case realist = "Realist"

    var description: String {
        switch self {
        case .motivational: return "Hopeful, uplifting, and action-oriented. Encourage forward momentum without clichés."
        case .naval: return "Speak like Naval Ravikant."
        case .philosophical: return "Deep, contemplative, and thought-provoking. Reference philosophy, existentialism, stoicism. Make them think."
        case .realist: return "Practical, grounded, and honest. Focus on facts and actionable steps. Skip the fluff."
        }
    }

    static func fromStoredValue(_ value: String) -> QuoteTone? {
        if value == "Tough Love" {
            return .motivational
        }
        return QuoteTone(rawValue: value)
    }
}

enum UserFocus: String, CaseIterable, Codable {
    case anxiety = "Overcoming Anxiety"
    case innerPeace = "Finding Inner Peace"
    case perspective = "Gaining Perspective"
    case confidence = "Building Confidence"
}

enum UserBarrier: String, CaseIterable, Codable {
    case procrastination = "Procrastination"
    case selfDoubt = "Self-Doubt"
    case burnout = "Burnout"
    case lackOfClarity = "Lack of Clarity"
    case externalFactors = "External Factors"
}

enum UserEnergyDrain: String, CaseIterable, Codable {
    case career = "Career"
    case relationship = "Relationship"
    case mediaNews = "Media & News"
    case healthFitness = "Health & Fitness"
}

enum ChatBackground: String, CaseIterable, Codable {
    case summit = "summit"
    case ascent = "ascent"
    case dawnRun = "dawnRun"
    case defaultBackground = "default"
}

enum AppLanguage: String, CaseIterable, Codable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case chinese = "zh"
    case hindi = "hi"
    case japanese = "ja"
    case korean = "ko"

    var promptName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .chinese: return "Chinese"
        case .hindi: return "Hindi"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        }
    }
}
