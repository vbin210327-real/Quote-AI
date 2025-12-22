//
//  FavoriteQuotesManager.swift
//  Quote AI
//
//  Manages saved/favorite quotes with persistence
//

import Foundation
import Combine

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
    }

    func removeQuote(_ quote: SavedQuote) {
        savedQuotes.removeAll { $0.id == quote.id }
        persistQuotes()
    }

    func removeQuote(byContent content: String) {
        savedQuotes.removeAll { $0.content == content }
        persistQuotes()
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
}
