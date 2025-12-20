//
//  ConversationHistoryView.swift
//  Quote AI
//
//  Displays list of past conversations
//

import SwiftUI

struct ConversationHistoryView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var localization = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var conversations: [Conversation] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedConversation: Conversation?
    @State private var showingDeleteAlert = false
    @State private var conversationToDelete: Conversation?
    
    var onSelectConversation: ((Conversation) -> Void)?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if isLoading {
                    loadingView
                } else if conversations.isEmpty {
                    emptyStateView
                } else {
                    conversationList
                }
            }
            .navigationTitle(localization.string(for: "history.title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .task {
            await loadConversations()
        }
        .alert(localization.string(for: "history.deleteConfirm"), isPresented: $showingDeleteAlert) {
            Button(localization.string(for: "history.cancel"), role: .cancel) { }
            Button(localization.string(for: "history.delete"), role: .destructive) {
                if let conversation = conversationToDelete {
                    Task {
                        await deleteConversation(conversation)
                    }
                }
            }
        } message: {
            Text(localization.string(for: "history.deleteMessage"))
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text(localization.string(for: "history.loading"))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(localization.string(for: "history.empty"))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(localization.string(for: "history.emptyDescription"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: { dismiss() }) {
                Text(localization.string(for: "history.startChat"))
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.black)
                    .cornerRadius(25)
            }
        }
    }
    
    private var conversationList: some View {
        List {
            ForEach(groupedConversations.keys.sorted(by: >), id: \.self) { date in
                Section {
                    ForEach(groupedConversations[date] ?? []) { conversation in
                        ConversationRow(conversation: conversation)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onSelectConversation?(conversation)
                                dismiss()
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    conversationToDelete = conversation
                                    showingDeleteAlert = true
                                } label: {
                                    Label(localization.string(for: "history.delete"), systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    Text(formatSectionDate(date))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .textCase(.none)
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await loadConversations()
        }
    }
    
    // MARK: - Helpers
    
    private var groupedConversations: [Date: [Conversation]] {
        Dictionary(grouping: conversations) { conversation in
            Calendar.current.startOfDay(for: conversation.createdAt)
        }
    }
    
    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return localization.string(for: "history.today")
        } else if calendar.isDateInYesterday(date) {
            return localization.string(for: "history.yesterday")
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    private func loadConversations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            conversations = try await supabaseManager.fetchConversations()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func deleteConversation(_ conversation: Conversation) async {
        do {
            try await supabaseManager.deleteConversation(conversationId: conversation.id)
            // Remove from local list
            conversations.removeAll { $0.id == conversation.id }
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
        }
    }
}

// MARK: - Conversation Row

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.08))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.black.opacity(0.7))
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Text(formatTime(conversation.updatedAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(.vertical, 8)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    ConversationHistoryView()
}
