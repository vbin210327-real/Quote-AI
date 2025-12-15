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
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom header with subtle divider
                VStack(spacing: 0) {
                    HStack {
                        ProfileButton()

                        Spacer()

                        Text("Quote AI")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()

                        // Invisible spacer to balance the profile button
                        Color.clear
                            .frame(width: 32, height: 32)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    // Subtle divider line
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 0.5)
                }
                .background(Color.black.opacity(0.2))

                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            if viewModel.isLoading {
                                LoadingIndicator()
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
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isInputFocused) { focused in
                        // Only scroll when keyboard appears, let SwiftUI handle dismiss
                        if focused, let lastMessage = viewModel.messages.last {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
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
                    TextField("What's on your mind?", text: $viewModel.currentInput, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(20)
                        .lineLimit(1...5)
                        .focused($isInputFocused)
                        .foregroundColor(.white)
                        .onSubmit {
                            viewModel.sendMessage()
                        }

                    Button(action: {
                        viewModel.sendMessage()
                    }) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(width: 32, height: 32)
                            .background(
                                viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading
                                ? Color.white.opacity(0.5)
                                : Color.white
                            )
                            .clipShape(Circle())
                    }
                    .disabled(viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
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

struct ProfileButton: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var showingProfile = false
    
    var body: some View {
        Button(action: {
            showingProfile = true
        }) {
            Image(systemName: "person.circle.fill")
                .font(.title2)
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
    }
}

struct ProfileView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isSigningOut = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if let email = supabaseManager.currentUser?.email {
                        HStack {
                            Text("Email")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(email)
                        }
                    }
                    
                    if let userId = supabaseManager.currentUser?.id {
                        HStack {
                            Text("User ID")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(userId.uuidString.prefix(8) + "...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
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
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                    .disabled(isSigningOut)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
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

    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 50)
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .padding(message.isUser ? 12 : 0)
                    .background(
                        message.isUser
                        ? AnyShapeStyle(Color.white.opacity(0.25)) 
                        : AnyShapeStyle(Color.clear)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(message.isUser ? 18 : 0)
                    .italic(!message.isUser)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            }
            .padding(.horizontal, message.isUser ? 0 : 4)

            if !message.isUser {
                Spacer(minLength: 50)
            }
        }
    }
}

struct LoadingIndicator: View {
    @State private var shimmerOffset: CGFloat = -1.0
    
    var body: some View {
        HStack {
            Text("Quoting...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.gray)
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
                        Text("Quoting...")
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
