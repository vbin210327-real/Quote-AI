//
//  ChatView.swift
//  Quote AI
//
//  Main chat interface
//

import SwiftUI
import Auth
import UIKit
import PhotosUI
import StoreKit

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var preferences = UserPreferences.shared
    @StateObject private var localization = LocalizationManager.shared
    @FocusState private var isInputFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var typingMessageId: UUID?
    @State private var showingProfile = false
    @State private var showingUpgradeAlert = false
    @State private var showingUpgradePlan = false
    @Environment(\.requestReview) private var requestReview

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
                                        },
                                        onShare: { content in
                                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                               let rootViewController = windowScene.windows.first?.rootViewController {
                                                var topController = rootViewController
                                                while let presentedController = topController.presentedViewController {
                                                    topController = presentedController
                                                }
                                                ShareManager.shared.shareQuote(content, from: topController)
                                            }
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
                .onReceive(NotificationCenter.default.publisher(for: .quoteReviewRequest)) { _ in
                    requestReview()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
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
                        .onChange(of: typingMessageId) { _, newValue in
                            guard newValue != nil else { return }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation {
                                    proxy.scrollTo("loading", anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: viewModel.isLoading) { _, isLoading in
                            if isLoading {
                                // Slightly longer delay to ensure the loading view is actually rendered and layout is updated
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        proxy.scrollTo("loading", anchor: .bottom)
                                    }
                                }
                            }
                        }
                        .onChange(of: isInputFocused) { _, focused in
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
            .onChange(of: showingProfile) { _, isOpen in
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
        .onChange(of: viewModel.showPaywall) { _, shouldShow in
            print("🔍 [ChatView] showPaywall changed to: \(shouldShow)")
            if shouldShow {
                print("⚠️ [ChatView] Showing upgrade alert!")
                showingUpgradeAlert = true
                viewModel.showPaywall = false
            }
        }
        .alert(localization.string(for: "chat.subscriptionRequired"), isPresented: $showingUpgradeAlert) {
            Button(localization.string(for: "chat.upgradePlan")) {
                showingUpgradePlan = true
            }
            Button(localization.string(for: "chat.maybeLater"), role: .cancel) { }
        } message: {
            Text(localization.string(for: "chat.subscriptionExpiredMessage"))
        }
        .sheet(isPresented: $showingUpgradePlan, onDismiss: {
            // Refresh subscription status after upgrade sheet closes
            Task {
                await SubscriptionManager.shared.checkSubscriptionStatus()
            }
        }) {
            UpgradePlanView()
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
    @StateObject private var preferences = UserPreferences.shared
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
                            .onChange(of: searchText) { _, _ in
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
                            Image(systemName: "bookmark")
                                .foregroundColor(.primary)
                            Text(localization.string(for: "favorites.title"))
                                .foregroundColor(.primary)
                            Spacer()
                            if !favoritesManager.savedQuotes.isEmpty {
                                Text("\(favoritesManager.savedQuotes.count)")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.black)
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
                            Text(localization.string(for: "history.noConversations"))
                                .foregroundColor(.secondary)
                        } else {
                            Text(localization.string(for: "history.noConversationsFound"))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        ForEach(conversations) { conversation in
                            Button(action: {
                                onSelectConversation?(conversation)
                                onClose?()
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    highlightedSnippet(conversation.title, query: searchText)
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
                    if let data = preferences.profileImage, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gray)
                            )
                    }

                    // User info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(preferences.userName.isEmpty
                            ? (supabaseManager.currentUser?.email?.components(separatedBy: "@").first ?? "User")
                            : preferences.userName)
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
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Text(content)
        }

        var attributedString = AttributedString(content)
        let lowerContent = content.lowercased()
        let lowerQuery = query.lowercased()

        var searchIndex = lowerContent.startIndex
        while let range = lowerContent.range(of: lowerQuery, range: searchIndex..<lowerContent.endIndex) {
            if let attrRange = Range(range, in: attributedString) {
                attributedString[attrRange].foregroundColor = Color(red: 0.83, green: 0.69, blue: 0.22) // Gold color
                attributedString[attrRange].inlinePresentationIntent = .stronglyEmphasized
            }
            searchIndex = range.upperBound
        }

        return Text(attributedString)
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
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var preferences = UserPreferences.shared
    @StateObject private var localization = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview
    @State private var isSigningOut = false
    @State private var showingEditProfile = false
    @State private var showingSignOutAlert = false
    @State private var showingSubscriptionDetail = false
    @State private var showingUpgradePlan = false
    @State private var isRestoringPurchases = false
    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private let privacyURL = URL(string: "https://gist.github.com/vbin210327-real/131a5d4d01c2591efa84453c78d9ba9c")!

    var onClose: (() -> Void)?

    private var genderColor: Color {
        switch preferences.userGender.lowercased() {
        case "male": return Color.blue
        case "female": return Color.pink
        default: return Color.gray
        }
    }

    private var appVersionText: String {
        let raw = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let parts = raw.split(separator: ".")
        if parts.count == 1 {
            return "\(raw).0.0"
        }
        if parts.count == 2 {
            return "\(raw).0"
        }
        return raw
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    profileHeader
                        .padding(.top, 20)
                        .padding(.bottom, 30)

                    accountSection
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(localization.string(for: "settings.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .environment(\.locale, localization.currentLanguage.locale)
        .id(localization.currentLanguage)
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
                .presentationDetents([.fraction(0.7)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showingSubscriptionDetail) {
            SubscriptionDetailView()
        }
        .sheet(isPresented: $showingUpgradePlan) {
            UpgradePlanView()
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            // Avatar
            ZStack {
                if let data = preferences.profileImage, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        )
                }
            }
            .id(preferences.profileImage)

            // User name
            Text(preferences.userName.isEmpty
                ? (supabaseManager.currentUser?.email?.components(separatedBy: "@").first?.capitalized ?? "User")
                : preferences.userName)
                .font(.title2)
                .fontWeight(.semibold)
                .overlay(alignment: .trailing) {
                    if preferences.userGender.lowercased() == "male" || preferences.userGender.lowercased() == "female" {
                        Circle()
                            .fill(genderColor)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text(preferences.userGender.lowercased() == "male" ? "♂" : "♀")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 28)
                    }
                }

            // Email
            Text(supabaseManager.currentUser?.email ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Edit profile button
            Button(action: {
                showingEditProfile = true
            }) {
                Text(localization.string(for: "profile.edit"))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
            }
            .padding(.top, 4)
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(localization.string(for: "settings.account"))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                // Email row
                SettingsRow(icon: "envelope", title: localization.string(for: "profile.email")) {
                    Text(supabaseManager.currentUser?.email ?? "")
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Divider().padding(.leading, 56)

                // Subscription row (for subscribers - shows management sheet)
                if subscriptionManager.isProUser {
                    Button(action: {
                        showingSubscriptionDetail = true
                    }) {
                        SettingsRow(icon: "crown", title: localization.string(for: "settings.subscription")) {
                            HStack(spacing: 4) {
                                Text(subscriptionManager.subscriptionPlanName ?? "Active")
                                    .foregroundColor(.secondary)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, 56)
                }

                // Upgrade Plan row - only show if not subscribed OR not on yearly plan
                if !subscriptionManager.isProUser || (subscriptionManager.subscriptionPlanName?.lowercased() != "yearly") {
                    Button(action: {
                        showingUpgradePlan = true
                    }) {
                        SettingsRow(icon: "sparkles", title: localization.string(for: "settings.upgradePlan")) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, 56)
                }

                // Restore Purchases
                Button(action: {
                    Task {
                        isRestoringPurchases = true
                        _ = await subscriptionManager.restorePurchases()
                        isRestoringPurchases = false
                    }
                }) {
                    SettingsRow(icon: "arrow.clockwise", title: localization.string(for: "settings.restorePurchases")) {
                        if isRestoringPurchases {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(isRestoringPurchases)

                Divider().padding(.leading, 56)

                // Personality row
                SettingsRow(icon: "face.smiling", title: localization.string(for: "settings.personality")) {
                    Menu {
                        Picker(localization.string(for: "settings.personality"), selection: $preferences.quoteTone) {
                            ForEach(QuoteTone.allCases, id: \.self) { tone in
                                Text(tone.localizedName).tag(tone)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(preferences.quoteTone.localizedName)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Divider().padding(.leading, 56)

                // Language row
                SettingsRow(icon: "globe", title: localization.string(for: "settings.language")) {
                    Menu {
                        Picker(localization.string(for: "settings.language"), selection: $localization.currentLanguage) {
                            ForEach(AppLanguage.allCases, id: \.self) { language in
                                Text("\(language.flag) \(language.displayName)").tag(language)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(localization.currentLanguage.displayName)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Divider().padding(.leading, 56)

                // Appearance row
                SettingsRow(icon: "paintpalette", title: localization.string(for: "settings.background")) {
                    Menu {
                        Picker(localization.string(for: "settings.background"), selection: $preferences.chatBackground) {
                            ForEach(ChatBackground.allCases, id: \.self) { background in
                                Text(background.localizedName).tag(background)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(preferences.chatBackground.localizedName)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal, 16)

            // Notifications section
            VStack(alignment: .leading, spacing: 0) {
                Text(localization.string(for: "settings.notifications"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    .padding(.top, 24)

                VStack(spacing: 0) {
                    // Daily Toggle
                    SettingsRow(icon: "bell.badge", title: localization.string(for: "settings.dailyQuote")) {
                        Toggle("", isOn: $preferences.notificationsEnabled)
                            .labelsHidden()
                            .tint(.black)
                    }

                    if preferences.notificationsEnabled {
                        Divider().padding(.leading, 56)

                        // Time Picker
                        SettingsRow(icon: "clock", title: localization.string(for: "settings.calibrationTime")) {
                            DatePicker("", selection: Binding(
                                get: {
                                    Calendar.current.date(bySettingHour: preferences.notificationHour, minute: preferences.notificationMinute, second: 0, of: Date()) ?? Date()
                                },
                                set: { newDate in
                                    let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                    preferences.notificationHour = components.hour ?? 8
                                    preferences.notificationMinute = components.minute ?? 0
                                }
                            ), displayedComponents: .hourAndMinute)
                            .labelsHidden()
                        }
                    }
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal, 16)
            }

            // About section
            VStack(alignment: .leading, spacing: 0) {
                Text(localization.string(for: "settings.about"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    .padding(.top, 24)

                VStack(spacing: 0) {
                    Button(action: { requestReview() }) {
                        SettingsRow(icon: "star", title: localization.string(for: "settings.rateApp")) {
                            EmptyView()
                        }
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, 56)

                    Button(action: { openURL(termsURL) }) {
                        SettingsRow(icon: "doc.text", title: localization.string(for: "paywall.termsOfUse")) {
                            EmptyView()
                        }
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, 56)

                    Button(action: { openURL(privacyURL) }) {
                        SettingsRow(icon: "hand.raised", title: localization.string(for: "paywall.privacyPolicy")) {
                            EmptyView()
                        }
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, 56)

                    SettingsRow(icon: "info.circle", title: localization.string(for: "settings.version")) {
                        Text(appVersionText)
                            .foregroundColor(.secondary)
                    }
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal, 16)
            }

            // Separate Logout section to prevent accidental taps
            VStack(spacing: 0) {
                Button(action: { showingSignOutAlert = true }) {
                    HStack(spacing: 16) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 18))
                            .foregroundColor(.red)
                            .frame(width: 24)

                        Text(localization.string(for: "profile.signOut"))
                            .foregroundColor(.red)

                        Spacer()

                        if isSigningOut {
                            ProgressView()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
                .disabled(isSigningOut)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .alert(localization.string(for: "profile.signOut"), isPresented: $showingSignOutAlert) {
                Button(localization.string(for: "profile.signOut"), role: .destructive) {
                    handleSignOut()
                }
                Button(localization.string(for: "history.cancel"), role: .cancel) { }
            } message: {
                Text(localization.string(for: "profile.signOutMessage") == "profile.signOutMessage" ? "Are you sure you want to sign out?" : localization.string(for: "profile.signOutMessage"))
            }
        }
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

// MARK: - Subscription Detail View
struct SubscriptionDetailView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var localization = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // App info card
                    VStack(spacing: 16) {
                        // App icon - using app icon from assets
                        if let uiImage = UIImage(named: "AppIcon") ?? UIImage(named: "AppIcon60x60") {
                            Image(uiImage: uiImage)
                                .resizable()
                                .frame(width: 60, height: 60)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        } else {
                            // Fallback: recreate the app icon style (white quote marks on black)
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.black)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text("❞")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                        
                        // App name
                        Text("Quote AI")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 20)
                    
                    // Subscription details card
                    VStack(alignment: .leading, spacing: 0) {
                        // Price row
                        HStack(spacing: 12) {
                            Image(systemName: "creditcard")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                                .frame(width: 24)
                            
                            Text(subscriptionPriceText)
                                .font(.body)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        
                        Divider().padding(.leading, 52)
                        
                        // Renewal date row
                        if let expirationDate = subscriptionManager.expirationDate {
                            HStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                                    .frame(width: 24)
                                
                                Text(subscriptionManager.willRenew
                                    ? localization.string(for: "subscription.renewsOn") + " " + expirationDate.formatted(date: .long, time: .omitted)
                                    : localization.string(for: "subscription.expiresOn") + " " + expirationDate.formatted(date: .long, time: .omitted))
                                    .font(.body)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                    }
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
                    
                    // Cancel subscription button
                    VStack(alignment: .leading, spacing: 8) {
                        Button(action: {
                            // Open App Store subscription management
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                openURL(url)
                            }
                        }) {
                            Text(localization.string(for: "subscription.cancel"))
                                .font(.body)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                        }
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        
                        // Cancel info text
                        if let expirationDate = subscriptionManager.expirationDate {
                            Text(localization.string(for: "subscription.cancelInfo")
                                .replacingOccurrences(of: "{date}", with: expirationDate.formatted(date: .long, time: .omitted)))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(localization.string(for: "subscription.editTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.string(for: "subscription.done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Refresh subscription info when view appears
                Task {
                    await subscriptionManager.checkSubscriptionStatus()
                }
            }
        }
    }

    private var subscriptionPriceText: String {
        switch subscriptionManager.subscriptionPlanName {
        case "Weekly":
            return localization.string(for: "subscription.priceWeekly")
        case "Monthly":
            return localization.string(for: "subscription.priceMonthly")
        case "Yearly":
            return localization.string(for: "subscription.priceYearly")
        default:
            return localization.string(for: "subscription.pricePro")
        }
    }
}

// MARK: - Settings Row
struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let content: Content

    init(icon: String, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.primary)
                .frame(width: 24)

            Text(title)
                .foregroundColor(.primary)

            Spacer()

            content
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @ObservedObject private var preferences = UserPreferences.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var displayName: String = ""
    @State private var isSaving = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    private var genderIcon: String? {
        switch preferences.userGender.lowercased() {
        case "male": return "person.fill"
        case "female": return "person.fill"
        default: return nil
        }
    }

    private var genderColor: Color {
        switch preferences.userGender.lowercased() {
        case "male": return Color.blue
        case "female": return Color.pink
        default: return Color.gray
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Avatar with gender indicator and camera button
            PhotosPicker(selection: $selectedItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    if let data = selectedImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color(UIColor.systemGray5))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color(UIColor.systemGray2))
                            )
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 24)

            // Name field
            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizationManager.shared.string(for: "profile.name"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)

                TextField(LocalizationManager.shared.string(for: "profile.namePlaceholder"), text: $displayName)
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 20)

            // Save button
            Button(action: {
                saveProfile()
            }) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: colorScheme == .dark ? .black : .white))
                            .padding(.trailing, 8)
                    }
                    Text(LocalizationManager.shared.string(for: "profile.save"))
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(colorScheme == .dark ? .black : .white)
                .frame(width: 240)
                .frame(height: 60)
                .background(colorScheme == .dark ? Color.white : Color.black)
                .cornerRadius(30)
            }
            .disabled(isSaving)
            .padding(.top, 40)

            // Cancel button
            Button(action: { dismiss() }) {
                Text(LocalizationManager.shared.string(for: "profile.cancel"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .onAppear {
            displayName = preferences.userName
            selectedImageData = preferences.profileImage
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                }
            }
        }
    }

    private func saveProfile() {
        isSaving = true
        preferences.userName = displayName
        if let data = selectedImageData {
            preferences.profileImage = data
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            dismiss()
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    var onTypingComplete: (() -> Void)? = nil
    var onCopy: (() -> Void)? = nil
    var onRegenerate: ((QuoteTone?) -> Void)? = nil
    var onShare: ((String) -> Void)? = nil
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
                        LikeButton(
                            isSaved: favoritesManager.isSaved(message.content),
                            color: actionColor,
                            action: {
                                favoritesManager.toggleSave(message.content)
                            }
                        )
                        
                        if let onShare {
                            Button(action: {
                                onShare(message.content)
                            }) {
                                Image(systemName: "arrowshape.turn.up.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(actionColor)
                                    .padding(6)
                            }
                        }

                        if let onRegenerate {
                            Menu {
                                Button {
                                    onRegenerate(nil)
                                } label: {
                                    Text(LocalizationManager.shared.string(for: "chat.regenerate"))
                                }
                                
                                Divider()
                                
                                ForEach(QuoteTone.allCases, id: \.self) { tone in
                                    Button {
                                        onRegenerate(tone)
                                    } label: {
                                        Text(tone.localizedName)
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

struct LikeButton: View {
    let isSaved: Bool
    let color: Color
    let action: () -> Void
    
    @State private var showParticles = false
    @State private var bookmarkScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            action()
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            if !isSaved { // Turning ON (since action already toggled state, actually check might be tricky if async, but here sync)
                // Wait, if action() toggles, then isSaved passed in *next* render will be true.
                // But inside this action block, isSaved is the old value?
                // Actually, action() might be async or SwiftUI updates later.
                // Assuming immediate toggle is NOT guaranteed to be reflected in `isSaved` variable *instantly* inside this closure if it's a let property.
                // But we know the intent: if current `isSaved` is false, we are turning it on.
                animate()
            } else {
                // Unlike animation
                withAnimation(.easeInOut(duration: 0.1)) {
                    bookmarkScale = 0.8
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6).delay(0.1)) {
                    bookmarkScale = 1.0
                }
            }
        }) {
            ZStack {
                // Particles
                if showParticles {
                    ForEach(0..<8) { i in
                        ParticleView(angle: .degrees(Double(i) * 45))
                    }
                }
                
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSaved ? .blue : color)
                    .scaleEffect(bookmarkScale)
            }
            .padding(6)
        }
        // Watch for external changes if needed, but the button triggers it mostly.
        // Actually, if we use local state logic based on `isSaved` (which is external), we might rely on the button tap.
        // However, if we want to ensure animation happens even if we tap quickly, we trigger it on tap.
    }
    
    private func animate() {
        // Bookmark Pulse
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            bookmarkScale = 1.4
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.1)) {
            bookmarkScale = 1.0
        }
        
        // Particles
        showParticles = true
        
        // Reset particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            showParticles = false 
        }
    }
}

struct ParticleView: View {
    let angle: Angle
    @State private var distance: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 1
    
    var body: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 3, height: 3)
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(x: 0, y: -distance)
            .rotationEffect(angle)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    distance = 18
                    opacity = 0
                    scale = 0.5
                }
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
