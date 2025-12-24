//
//  SavedQuotesView.swift
//  Quote AI
//
//  View to display and manage saved/favorite quotes
//

import SwiftUI

struct SavedQuotesView: View {
    @StateObject private var favoritesManager = FavoriteQuotesManager.shared
    @StateObject private var localization = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var quoteToDelete: SavedQuote?

    var body: some View {
        NavigationView {
            Group {
                if favoritesManager.savedQuotes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bookmark.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text(localization.string(for: "favorites.empty"))
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(localization.string(for: "favorites.emptyHint"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(favoritesManager.savedQuotes) { quote in
                            SavedQuoteRow(quote: quote)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        quoteToDelete = quote
                                        showingDeleteAlert = true
                                    } label: {
                                        Label(localization.string(for: "favorites.remove"), systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(localization.string(for: "favorites.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.string(for: "profile.done")) {
                        dismiss()
                    }
                    .foregroundColor(.black)
                }
            }
            .alert(localization.string(for: "favorites.removeConfirm"), isPresented: $showingDeleteAlert) {
                Button(localization.string(for: "history.cancel"), role: .cancel) { }
                Button(localization.string(for: "favorites.remove"), role: .destructive) {
                    if let quote = quoteToDelete {
                        withAnimation {
                            favoritesManager.removeQuote(quote)
                        }
                    }
                }
            } message: {
                Text(localization.string(for: "favorites.removeMessage"))
            }
        }
        .environment(\.locale, localization.currentLanguage.locale)
    }
}

struct SavedQuoteRow: View {
    let quote: SavedQuote
    @StateObject private var localization = LocalizationManager.shared
    @State private var isCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(quote.content)
                .font(.body)
                .italic()
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text(quote.savedAt.formatted(
                    Date.FormatStyle(date: .abbreviated, time: .shortened)
                        .locale(localization.currentLanguage.locale)
                ))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                // Copy button
                Button(action: {
                    UIPasteboard.general.string = quote.content
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    withAnimation {
                        isCopied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            isCopied = false
                        }
                    }
                }) {
                    Image(systemName: isCopied ? "checkmark" : "square.on.square")
                        .font(.system(size: 14))
                        .foregroundColor(isCopied ? .green : .secondary)
                }
                .buttonStyle(.plain)

                // Share button
                Button(action: {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        var topController = rootViewController
                        while let presentedController = topController.presentedViewController {
                            topController = presentedController
                        }
                        ShareManager.shared.shareQuote(quote.content, from: topController)
                    }
                }) {
                    Image(systemName: "arrowshape.turn.up.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    SavedQuotesView()
}
