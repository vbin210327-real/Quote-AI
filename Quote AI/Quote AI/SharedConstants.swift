import Foundation

struct SharedConstants {
    nonisolated static let appGroupIdentifier = "group.com.Quote-AI.dev"
    nonisolated static let suiteName = appGroupIdentifier
    
    struct Keys {
        nonisolated static let latestQuote = "latestQuote"
        nonisolated static let lastRefreshDate = "lastRefreshDate"
        nonisolated static let quoteTone = "quoteTone"
        nonisolated static let userBarrier = "userBarrier"
        nonisolated static let isGeneratingQuote = "isGeneratingQuote"
        nonisolated static let appLanguage = "appLanguage"
    }
}
