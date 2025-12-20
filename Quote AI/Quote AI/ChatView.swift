//
//  ChatView.swift
//  Quote AI
//
//  Main chat interface
//

import SwiftUI
import Auth

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @StateObject private var preferences = UserPreferences.shared
    @StateObject private var localization = LocalizationManager.shared
    @FocusState private var isInputFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var typingMessageId: UUID?

    private var isDefaultBackground: Bool {
        preferences.chatBackground == .defaultBackground
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom header with subtle divider
                VStack(spacing: 0) {
                    HStack {
                        ProfileButton { conversation in
                            Task {
                                await viewModel.loadConversation(conversation)
                            }
                        }

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
                                    }
                                )
                                    .id(message.id)
                            }

                            if viewModel.isLoading || typingMessageId != nil {
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

                    let isSendDisabled = viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading
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
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var preferences = UserPreferences.shared
    @State private var showingProfile = false
    
    var onSelectConversation: ((Conversation) -> Void)?
    
    var body: some View {
        Button(action: {
            showingProfile = true
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
        .sheet(isPresented: $showingProfile) {
            ProfileView(onSelectConversation: onSelectConversation)
        }
    }
}

struct ProfileView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var localization = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isSigningOut = false
    @State private var showingHistory = false
    
    var onSelectConversation: ((Conversation) -> Void)?
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if let email = supabaseManager.currentUser?.email {
                        HStack {
                            Text(localization.string(for: "profile.email"))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(email)
                        }
                    }

                    if let userId = supabaseManager.currentUser?.id {
                        HStack {
                            Text(localization.string(for: "profile.userId"))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(userId.uuidString.prefix(8) + "...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Conversation History
                Section {
                    Button(action: {
                        showingHistory = true
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(.black)
                            Text(localization.string(for: "history.title"))
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
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
            .navigationTitle(localization.string(for: "profile.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(localization.string(for: "profile.done")) {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingHistory) {
                ConversationHistoryView { conversation in
                    dismiss()
                    onSelectConversation?(conversation)
                }
            }
        }
    }
    
    private func handleSignOut() {
        isSigningOut = true
        Task {
            do {
                try await supabaseManager.signOut()
                dismiss()
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
    @StateObject private var preferences = UserPreferences.shared

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
                        onComplete: onTypingComplete
                    )
                    .padding(message.isUser ? 12 : 0)
                    .background(bubbleBackground)
                    .cornerRadius(message.isUser ? 18 : 0)
                    .shadow(
                        color: preferences.chatBackground == .defaultBackground ? .clear : .black.opacity(0.3),
                        radius: 2, x: 0, y: 1
                    )
                }
            }
            .padding(.horizontal, message.isUser ? 0 : 4)

            if !message.isUser {
                Spacer(minLength: 50)
            }
        }
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
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.6), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width / 2)
                            .offset(x: geo.size.width * shimmerOffset)
                    }
                    .mask(
                        Text(localization.string(for: "chat.loading"))
                            .font(.system(size: 16, weight: .medium))
                    )
                )
                .padding(.leading, 4) // Align with bubbles
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        shimmerOffset = 2.0
                    }
                }
            
            Spacer()
        }
        .padding(.vertical, 8)
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
