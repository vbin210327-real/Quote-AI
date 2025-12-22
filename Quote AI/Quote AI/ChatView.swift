//
//  ChatView.swift
//  Quote AI
//
//  Main chat interface
//

import SwiftUI
import Auth
import UIKit

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var preferences = UserPreferences.shared
    @StateObject private var localization = LocalizationManager.shared
    @FocusState private var isInputFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var typingMessageId: UUID?
    @State private var showingProfile = false

    private var isDefaultBackground: Bool {
        preferences.chatBackground == .defaultBackground
    }

    var body: some View {
        ZStack(alignment: .leading) {
            NavigationView {
                VStack(spacing: 0) {
                    // Custom header with subtle divider
                    VStack(spacing: 0) {
                        HStack {
                            ProfileButton(isPresented: $showingProfile)

                            Spacer()

                            Text(localization.string(for: "chat.title"))
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(isDefaultBackground ? .primary : .white)

                            Spacer()

                            // Invisible spacer to balance the profile button
                            Color.clear
                                .frame(width: 32, height: 32)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                        // Subtle divider line
                        Rectangle()
                            .fill(isDefaultBackground ? Color.primary.opacity(0.15) : Color.white.opacity(0.15))
                            .frame(height: 0.5)
                    }
                    .background(isDefaultBackground ? Color.clear : Color.black.opacity(0.2))

                    // Chat messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(
                                        message: message,
                                        onTypingComplete: {
                                            if typingMessageId == message.id {
                                                typingMessageId = nil
                                            }
                                        },
                                        onCopy: {
                                            UIPasteboard.general.string = message.content
                                        },
                                        onRegenerate: { tone in
                                            viewModel.regenerateMessage(for: message, tone: tone)
                                        }
                                    )
                                    .id(message.id)
                                }

                                if viewModel.isLoading {
                                    LoadingIndicator()
                                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                                        .id("loading")
                                }
                            }
                            .padding()
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .onTapGesture {
                            isInputFocused = false
                        }
                        .onChange(of: viewModel.messages.count) { _ in
                            // Scroll to bottom when new message arrives
                            if let lastMessage = viewModel.messages.last {
                                if lastMessage.shouldAnimate {
                                    typingMessageId = lastMessage.id
                                }
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: typingMessageId) { newValue in
                            guard newValue != nil else { return }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation {
                                    proxy.scrollTo("loading", anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: viewModel.isLoading) { isLoading in
                            if isLoading {
                                // Slightly longer delay to ensure the loading view is actually rendered and layout is updated
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        proxy.scrollTo("loading", anchor: .bottom)
                                    }
                                }
                            }
                        }
                        .onChange(of: isInputFocused) { focused in
                            if let lastMessage = viewModel.messages.last {
                                if focused {
                                    // Keyboard appearing - scroll after a short delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                    }
                                } else {
                                    // Keyboard dismissing - scroll after keyboard starts hiding
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Error message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }

                    // Token warning banner
                    if viewModel.showTokenWarning {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(localization.string(for: "chat.tokenWarning"))
                                .font(.caption)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }

                    // Token limit reached banner
                    if viewModel.isAtTokenLimit {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text(localization.string(for: "chat.tokenLimitReached"))
                                .font(.caption)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.15))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }

                    // Input area
                    HStack(spacing: 12) {
                        TextField(localization.string(for: "chat.placeholder"), text: $viewModel.currentInput, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(isDefaultBackground ? Color.gray.opacity(0.1) : Color.white.opacity(0.15))
                            .cornerRadius(20)
                            .lineLimit(1...5)
                            .focused($isInputFocused)
                            .foregroundColor(isDefaultBackground ? .primary : .white)
                            .onSubmit {
                                viewModel.sendMessage()
                            }

                        let isSendDisabled = viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading || viewModel.isAtTokenLimit
                        let isDarkMode = colorScheme == .dark
                        let activeForeground = (isDefaultBackground && isDarkMode) ? Color.black : (isDefaultBackground ? Color.white : Color.black)
                        let activeBackground = (isDefaultBackground && isDarkMode) ? Color.white : (isDefaultBackground ? Color.black : Color.white)

                        Button(action: {
                            viewModel.sendMessage()
                        }) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(
                                    isSendDisabled ? .gray : activeForeground
                                )
                                .frame(width: 32, height: 32)
                                .background(
                                    isSendDisabled ? Color.gray.opacity(0.3) : activeBackground
                                )
                                .clipShape(Circle())
                        }
                        .disabled(isSendDisabled)
                    }
                    .padding()
                }
                .background(
                    ChatBackgroundView(background: preferences.chatBackground)
                )
                .navigationBarHidden(true)
            }
            .blur(radius: showingProfile ? 3 : 0)
            .disabled(showingProfile) // Disable interaction with chat when profile is open
            .onChange(of: showingProfile) { isOpen in
                if isOpen {
                    isInputFocused = false // Dismiss keyboard when drawer opens
                }
            }

            // Dimming Layer
            if showingProfile {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showingProfile = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
            }

            // Side Drawer
            if showingProfile {
                ProfileView(
                    isChatBusy: viewModel.isLoading,
                    onSelectConversation: { conversation in
                        withAnimation {
                            showingProfile = false
                        }
                        Task {
                            await viewModel.loadConversation(conversation)
                        }
                    },
                    onClose: {
                        withAnimation {
                            showingProfile = false
                        }
                    },
                    onNewChat: {
                        withAnimation {
                            showingProfile = false
                        }
                        viewModel.clearChat()
                    }
                )
                .frame(width: UIScreen.main.bounds.width * 0.85)
                .background(Color(UIColor.systemBackground))
                .transition(.move(edge: .leading))
                .zIndex(2)
            }
        }
    }
}

private struct ChatBackgroundView: View {
    let background: ChatBackground

    var body: some View {
        if background == .defaultBackground {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
        } else {
            Image(background.assetName)
                .resizable()
                .scaledToFill()
                .id(background.assetName)
                .ignoresSafeArea()
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.25),
                            Color.black.opacity(0.1),
                            Color.black.opacity(0.25)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .transaction { transaction in
                    transaction.animation = nil
                }
        }
    }
}

struct ProfileButton: View {
    @StateObject private var preferences = UserPreferences.shared
    @Binding var isPresented: Bool

    var body: some View {
        Button(action: {
            // Dismiss keyboard first
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isPresented = true
            }
        }) {
            // Custom align-center icon (three horizontal lines)
            ZStack {
                Canvas { context, size in
                    let lineColor = preferences.chatBackground == .defaultBackground ? Color.primary : Color.white
                    
                    // Top line (longest)
                    let topPath = Path { path in
                        path.move(to: CGPoint(x: size.width * 0.15, y: size.height * 0.25))
                        path.addLine(to: CGPoint(x: size.width * 0.85, y: size.height * 0.25))
                    }
                    context.stroke(topPath, with: .color(lineColor), lineWidth: 2)
                    
                    // Middle line (shortest)
                    let middlePath = Path { path in
                        path.move(to: CGPoint(x: size.width * 0.30, y: size.height * 0.50))
                        path.addLine(to: CGPoint(x: size.width * 0.70, y: size.height * 0.50))
                    }
                    context.stroke(middlePath, with: .color(lineColor), lineWidth: 2)
                    
                    // Bottom line (medium)
                    let bottomPath = Path { path in
                        path.move(to: CGPoint(x: size.width * 0.20, y: size.height * 0.75))
                        path.addLine(to: CGPoint(x: size.width * 0.80, y: size.height * 0.75))
                    }
                    context.stroke(bottomPath, with: .color(lineColor), lineWidth: 2)
                }
                .frame(width: 28, height: 28)
            }
        }
    }
}

struct ProfileView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var localization = LocalizationManager.shared
    @StateObject private var favoritesManager = FavoriteQuotesManager.shared
    @State private var searchText = ""
    @State private var conversations: [Conversation] = []
    @State private var isLoading = true
    @State private var searchTask: Task<Void, Never>?
    @State private var showingDeleteAlert = false
    @State private var conversationToDelete: Conversation?
    @State private var showingSavedQuotes = false
    @State private var showingSettings = false

    let isChatBusy: Bool
    var onSelectConversation: ((Conversation) -> Void)?
    var onClose: (() -> Void)?
    var onNewChat: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            List {
                // Search Bar
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField(localization.string(for: "history.search"), text: $searchText)
                            .onChange(of: searchText) { newValue in
                                searchTask?.cancel()
                                searchTask = Task {
                                    try? await Task.sleep(nanoseconds: 300_000_000)
                                    if Task.isCancelled { return }
                                    await loadConversations()
                                }
                            }
                    }
                }

                Section {
                    Button(action: {
                        onNewChat?()
                    }) {
                        HStack(spacing: 8) {
                            SquarePenIcon(size: 18)
                            Text(localization.string(for: "history.newChat"))
                        }
                        .foregroundColor(.primary)
                    }
                    .disabled(isChatBusy)
                }

                // Saved Quotes Section
                Section {
                    Button(action: {
                        showingSavedQuotes = true
                    }) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text(localization.string(for: "favorites.title"))
                                .foregroundColor(.primary)
                            Spacer()
                            if !favoritesManager.savedQuotes.isEmpty {
                                Text("\(favoritesManager.savedQuotes.count)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Conversations List
                Section {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding()
                            Spacer()
                        }
                    } else if conversations.isEmpty {
                        if searchText.isEmpty {
                            Text("No conversations yet")
                                .foregroundColor(.secondary)
                        } else {
                            Text("No conversations found")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        ForEach(conversations) { conversation in
                            Button(action: {
                                onSelectConversation?(conversation)
                                onClose?()
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(conversation.title)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)

                                    if let snippet = conversation.snippet {
                                        highlightedSnippet(snippet, query: searchText)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }

                                    Text(
                                        conversation.createdAt.formatted(
                                            Date.FormatStyle(date: .abbreviated, time: .shortened)
                                                .locale(localization.currentLanguage.locale)
                                        )
                                    )
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 2)
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
                    }
                } header: {
                    Text(localization.string(for: "history.title"))
                }
            }
            .scrollDismissesKeyboard(.immediately)

            // Profile button at bottom
            Button(action: {
                showingSettings = true
            }) {
                HStack(spacing: 12) {
                    // Avatar
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                        )

                    // User info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(supabaseManager.currentUser?.email?.components(separatedBy: "@").first ?? "User")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(UIColor.systemBackground))
            }
        }
        .ignoresSafeArea(.keyboard)
        .task {
            await loadConversations()
        }
        .environment(\.locale, localization.currentLanguage.locale)
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
        .sheet(isPresented: $showingSavedQuotes) {
            SavedQuotesView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(onClose: onClose)
        }
    }

    private func loadConversations() async {
        isLoading = true
        do {
            if searchText.isEmpty {
                conversations = try await supabaseManager.fetchConversations()
            } else {
                do {
                    conversations = try await supabaseManager.searchConversations(query: searchText)
                } catch {
                    print("Server search failed, falling back to local title search: \(error)")
                    let allConversations = try await supabaseManager.fetchConversations()
                    conversations = allConversations.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
                }
            }
        } catch {
            print("Error loading conversations: \(error)")
        }
        isLoading = false
    }

    private func highlightedSnippet(_ content: String, query: String) -> Text {
        if query.isEmpty { return Text(content) }

        let lowerContent = content.lowercased()
        let lowerQuery = query.lowercased()
        var lastIndex = lowerContent.startIndex
        var result = Text("")

        while let range = lowerContent.range(of: lowerQuery, range: lastIndex..<lowerContent.endIndex) {
            let before = String(content[lastIndex..<range.lowerBound])
            let match = String(content[range])

            result = result + Text(before)
            result = result + Text(match).foregroundColor(Color(red: 0.95, green: 0.79, blue: 0.3)).bold()

            lastIndex = range.upperBound
        }

        let remaining = String(content[lastIndex..<content.endIndex])
        result = result + Text(remaining)

        return result
    }

    private func deleteConversation(_ conversation: Conversation) async {
        do {
            try await supabaseManager.deleteConversation(conversationId: conversation.id)
            conversations.removeAll { $0.id == conversation.id }
        } catch {
            print("Error deleting conversation: \(error)")
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var preferences = UserPreferences.shared
    @StateObject private var localization = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isSigningOut = false

    var onClose: (() -> Void)?

    private func localizedTone(_ tone: QuoteTone) -> String {
        switch tone {
        case .gentle: return localization.string(for: "tone.gentle")
        case .toughLove: return localization.string(for: "tone.toughLove")
        case .philosophical: return localization.string(for: "tone.philosophical")
        case .realist: return localization.string(for: "tone.realist")
        }
    }

    var body: some View {
        NavigationView {
            List {
                // Personality Selection
                Section {
                    ForEach(QuoteTone.allCases, id: \.self) { tone in
                        Button(action: {
                            preferences.quoteTone = tone
                        }) {
                            HStack {
                                Image(systemName: tone.icon)
                                    .foregroundColor(.primary)
                                Text(localizedTone(tone))
                                    .foregroundColor(.primary)
                                Spacer()
                                if preferences.quoteTone == tone {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text(localization.string(for: "settings.personality"))
                }

                // Language Selection
                Section {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Button(action: {
                            localization.setLanguage(language)
                        }) {
                            HStack {
                                Text(language.flag)
                                Text(language.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if localization.currentLanguage == language {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text(localization.string(for: "settings.language"))
                }

                // Sign Out
                Section {
                    Button(action: {
                        handleSignOut()
                    }) {
                        HStack {
                            if isSigningOut {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(localization.string(for: "profile.signOut"))
                                .foregroundColor(.red)
                        }
                    }
                    .disabled(isSigningOut)
                }
            }
            .navigationTitle(localization.string(for: "settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .environment(\.locale, localization.currentLanguage.locale)
    }

    private func handleSignOut() {
        isSigningOut = true
        Task {
            do {
                try await supabaseManager.signOut()
                dismiss()
                onClose?()
            } catch {
                print("Error signing out: \(error)")
            }
            isSigningOut = false
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    var onTypingComplete: (() -> Void)? = nil
    var onCopy: (() -> Void)? = nil
    var onRegenerate: ((QuoteTone?) -> Void)? = nil
    @StateObject private var preferences = UserPreferences.shared
    @StateObject private var favoritesManager = FavoriteQuotesManager.shared
    @State private var isAnimationCompleted = false
    @State private var isCopied = false

    var body: some View {
        let textColor = preferences.chatBackground == .defaultBackground ? Color.primary : Color.white
        let bubbleBackground = message.isUser
        ? AnyShapeStyle(preferences.chatBackground == .defaultBackground ? Color.primary.opacity(0.08) : Color.white.opacity(0.25))
        : AnyShapeStyle(Color.clear)
        let isItalic = !message.isUser && preferences.chatBackground != .defaultBackground
        let typingSpeed: TimeInterval = {
            let length = message.content.count
            if length > 240 { return 0.012 }
            if length > 120 { return 0.016 }
            return 0.02
        }()

        HStack {
            if message.isUser {
                Spacer(minLength: 50)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                if message.isUser || !message.shouldAnimate {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(textColor)
                        .italic(isItalic)
                        .padding(message.isUser ? 12 : 0)
                        .background(bubbleBackground)
                        .cornerRadius(message.isUser ? 18 : 0)
                        .shadow(
                            color: preferences.chatBackground == .defaultBackground ? .clear : .black.opacity(0.3),
                            radius: 2, x: 0, y: 1
                        )
                } else {
                    TypewriterView(
                        text: message.content,
                        font: .body,
                        textColor: textColor,
                        isItalic: isItalic,
                        speed: typingSpeed,
                        isActive: true,
                        enableHaptics: false,
                        onComplete: {
                            isAnimationCompleted = true
                            onTypingComplete?()
                        }
                    )
                    .padding(message.isUser ? 12 : 0)
                    .background(bubbleBackground)
                    .cornerRadius(message.isUser ? 18 : 0)
                    .shadow(
                        color: preferences.chatBackground == .defaultBackground ? .clear : .black.opacity(0.3),
                        radius: 2, x: 0, y: 1
                    )
                }

                if !message.isUser && !message.isWelcome && (!message.shouldAnimate || isAnimationCompleted) {
                    HStack(spacing: 16) {
                        if let onCopy {
                            Button(action: {
                                onCopy()
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
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(actionColor)
                                    .padding(6)
                            }
                        }

                        // Save/Favorite button
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                favoritesManager.toggleSave(message.content)
                            }
                        }) {
                            Image(systemName: favoritesManager.isSaved(message.content) ? "heart.fill" : "heart")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(favoritesManager.isSaved(message.content) ? .red : actionColor)
                                .padding(6)
                        }

                        if let onRegenerate {
                            Menu {
                                Button {
                                    onRegenerate(nil)
                                } label: {
                                    Label(LocalizationManager.shared.string(for: "chat.welcome.getStarted") == "Get Started" ? "Regenerate" : "重新生成", systemImage: "arrow.clockwise")
                                }
                                
                                Divider()
                                
                                ForEach(QuoteTone.allCases, id: \.self) { tone in
                                    Button {
                                        onRegenerate(tone)
                                    } label: {
                                        Label(tone.localizedName, systemImage: tone.icon)
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(actionColor)
                                    .frame(width: 26, height: 26)
                                    .contentShape(Rectangle())
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                }
            }
            .padding(.horizontal, message.isUser ? 0 : 4)

            if !message.isUser {
                Spacer(minLength: 50)
            }
        }
    }

    private var actionColor: Color {
        preferences.chatBackground == .defaultBackground
        ? Color.secondary
        : Color.white.opacity(0.8)
    }
}

struct LoadingIndicator: View {
    @StateObject private var localization = LocalizationManager.shared
    @State private var shimmerOffset: CGFloat = -1.0

    var body: some View {
        HStack {
            Text(localization.string(for: "chat.loading"))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(LocalizationManager.shared.currentLanguage == .english ? .gray : .secondary)
                .overlay(
                    GeometryReader { geo in
                        Rectangle()
                            .fill(shimmerGradient)
                            .frame(width: geo.size.width / 2)
                            .offset(x: geo.size.width * shimmerOffset)
                    }
                    .mask(
                        Text(localization.string(for: "chat.loading"))
                            .font(.system(size: 16, weight: .medium))
                    )
                )
                .padding(.leading, 4) // Align with bubbles

            Spacer()
        }
        .padding(.vertical, 8)
        .onAppear {
            startShimmer()
        }
    }

    private var shimmerGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.clear,
                Color.primary.opacity(0.6),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func startShimmer() {
        shimmerOffset = -1.0
        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
            shimmerOffset = 2.0
        }
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ChatView()
}

extension QuoteTone {
    var localizedName: String {
        switch self {
        case .gentle: return LocalizationManager.shared.string(for: "tone.gentle")
        case .toughLove: return LocalizationManager.shared.string(for: "tone.toughLove")
        case .philosophical: return LocalizationManager.shared.string(for: "tone.philosophical")
        case .realist: return LocalizationManager.shared.string(for: "tone.realist")
        }
    }
}
