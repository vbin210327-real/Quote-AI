//
//  FavoriteQuotesManager.swift
//  Quote AI
//
//  Manages saved/favorite quotes with persistence and cloud sync
//

import Foundation
import Combine
import NotificationCenter

struct SavedQuote: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let savedAt: Date

    init(id: UUID = UUID(), content: String, savedAt: Date = Date()) {
        self.id = id
        self.content = content
        self.savedAt = savedAt
    }
}

class FavoriteQuotesManager: ObservableObject {
    static let shared = FavoriteQuotesManager()

    @Published private(set) var savedQuotes: [SavedQuote] = []

    private let userDefaultsKey = "savedQuotes"
    private let reviewSaveCountKey = "reviewSaveCount"
    private let reviewRequestedKey = "reviewRequested"
    private var isSyncingFromCloud = false

    private init() {
        loadQuotes()
    }

    // MARK: - Public Methods

    func saveQuote(_ content: String) {
        // Check if already saved
        guard !isSaved(content) else { return }

        let quote = SavedQuote(content: content)
        savedQuotes.insert(quote, at: 0) // Add to beginning
        persistQuotes()
        recordSaveForReviewPrompt()

        // Sync to cloud
        if !isSyncingFromCloud {
            Task {
                await saveQuoteToCloud(content: content)
            }
        }
    }

    func removeQuote(_ quote: SavedQuote) {
        let content = quote.content
        savedQuotes.removeAll { $0.id == quote.id }
        persistQuotes()

        // Sync deletion to cloud
        if !isSyncingFromCloud {
            Task {
                await deleteQuoteFromCloud(content: content)
            }
        }
    }

    func removeQuote(byContent content: String) {
        savedQuotes.removeAll { $0.content == content }
        persistQuotes()

        // Sync deletion to cloud
        if !isSyncingFromCloud {
            Task {
                await deleteQuoteFromCloud(content: content)
            }
        }
    }

    func isSaved(_ content: String) -> Bool {
        savedQuotes.contains { $0.content == content }
    }

    func toggleSave(_ content: String) {
        if isSaved(content) {
            removeQuote(byContent: content)
        } else {
            saveQuote(content)
        }
    }

    // MARK: - Cloud Sync

    /// Sync quotes from cloud (called on login - cloud wins)
    @MainActor
    func syncFromCloud() async {
        guard SupabaseManager.shared.isAuthenticated else { return }

        isSyncingFromCloud = true
        defer { isSyncingFromCloud = false }

        do {
            let cloudQuotes = try await SupabaseManager.shared.fetchSavedQuotes()

            // Replace local quotes with cloud quotes (cloud wins)
            savedQuotes = cloudQuotes.map { cloudQuote in
                SavedQuote(
                    id: cloudQuote.id,
                    content: cloudQuote.content,
                    savedAt: cloudQuote.savedAt
                )
            }
            persistQuotes()
        } catch {
            print("Failed to sync quotes from cloud: \(error)")
        }
    }

    /// Upload all local quotes to cloud (for initial sync when no cloud data exists)
    @MainActor
    func syncToCloud() async {
        guard SupabaseManager.shared.isAuthenticated else { return }

        for quote in savedQuotes {
            do {
                _ = try await SupabaseManager.shared.saveQuoteToCloud(content: quote.content)
            } catch {
                print("Failed to sync quote to cloud: \(error)")
            }
        }
    }

    /// Clear local quotes on logout
    func clearLocalData() {
        savedQuotes.removeAll()
        persistQuotes()
        UserDefaults.standard.removeObject(forKey: reviewSaveCountKey)
        UserDefaults.standard.removeObject(forKey: reviewRequestedKey)
    }

    // MARK: - Private Methods

    private func loadQuotes() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }

        do {
            let quotes = try JSONDecoder().decode([SavedQuote].self, from: data)
            savedQuotes = quotes
        } catch {
            print("Failed to load saved quotes: \(error)")
        }
    }

    private func persistQuotes() {
        do {
            let data = try JSONEncoder().encode(savedQuotes)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save quotes: \(error)")
        }
    }

    private func recordSaveForReviewPrompt() {
        let defaults = UserDefaults.standard
        let hasRequested = defaults.bool(forKey: reviewRequestedKey)
        guard !hasRequested else { return }

        let newCount = defaults.integer(forKey: reviewSaveCountKey) + 1
        defaults.set(newCount, forKey: reviewSaveCountKey)

        if newCount >= 3 {
            defaults.set(true, forKey: reviewRequestedKey)
            NotificationCenter.default.post(name: .quoteReviewRequest, object: nil)
        }
    }

    @MainActor
    private func saveQuoteToCloud(content: String) async {
        guard SupabaseManager.shared.isAuthenticated else { return }

        do {
            _ = try await SupabaseManager.shared.saveQuoteToCloud(content: content)
        } catch {
            print("Failed to save quote to cloud: \(error)")
        }
    }

    @MainActor
    private func deleteQuoteFromCloud(content: String) async {
        guard SupabaseManager.shared.isAuthenticated else { return }

        do {
            try await SupabaseManager.shared.deleteQuoteFromCloud(content: content)
        } catch {
            print("Failed to delete quote from cloud: \(error)")
        }
    }
}

extension Notification.Name {
    static let quoteReviewRequest = Notification.Name("quoteReviewRequest")
}
