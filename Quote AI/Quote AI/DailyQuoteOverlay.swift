import SwiftUI
import WidgetKit

struct DailyQuoteOverlay: View {
    let initialQuote: String
    @Binding var isPresented: Bool
    @StateObject private var favoritesManager = FavoriteQuotesManager.shared
    @StateObject private var localization = LocalizationManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var animateIn = false
    @State private var isSaved = false
    @State private var currentQuote: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showUpgradeSheet = false
    @State private var needsSubscription = false
    
    var body: some View {
        ZStack {
            // High-end Blur Background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .opacity(animateIn ? 1 : 0)
                .onTapGesture {
                    if !isLoading {
                        dismiss()
                    }
                }
            
            // Optional: Extra dark tint for contrast
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .opacity(animateIn ? 1 : 0)
            
            // Glassmorphism Card
            VStack(spacing: 30) {
                // Header
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text(localization.string(for: "settings.dailyQuote"))
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .italic()
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if !isLoading {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray.opacity(0.5))
                        }
                    }
                }
                .padding(.bottom, 10)
                
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("Calibrating your soul...")
                            .font(.system(size: 16, weight: .medium, design: .serif))
                            .italic()
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 150)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: needsSubscription ? "lock.fill" : "exclamationmark.triangle.fill")
                            .font(.title)
                            .foregroundStyle(
                                needsSubscription
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "F7B733"), Color(hex: "FC4A1A")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                : AnyShapeStyle(Color.orange)
                            )

                        Text(error)
                            .font(.system(size: 16))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        if !needsSubscription {
                            Button("Use Offline Quote") {
                                currentQuote = initialQuote
                                errorMessage = nil
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.blue)
                        } else {
                            Button(localization.string(for: "chat.upgradePlan")) {
                                showUpgradeSheet = true
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "111111"), Color(hex: "3A3A3A")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
                        }
                    }
                } else {
                    // Quote Text
                    Text(currentQuote)
                        .font(.custom("Georgia", size: 28))
                        .italic()
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .lineSpacing(8)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.5)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    
                    // Divider
                    Rectangle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 1)
                        .padding(.horizontal, 40)
                    
                    // Action Buttons
                    HStack(spacing: 40) {
                        // Save Button
                        Button(action: {
                            withAnimation(.spring()) {
                                favoritesManager.toggleSave(currentQuote)
                                isSaved = favoritesManager.isSaved(currentQuote)
                            }
                        }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(isSaved ? Color.blue : Color.gray.opacity(0.1))
                                        .frame(width: 56, height: 56)
                                    
                                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                                        .font(.title3)
                                        .foregroundColor(isSaved ? .white : .primary)
                                }
                                Text("Save")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Share Button
                        Button(action: {
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                               let rootViewController = windowScene.windows.first?.rootViewController {
                                var topController = rootViewController
                                while let presentedController = topController.presentedViewController {
                                    topController = presentedController
                                }
                                ShareManager.shared.shareQuote(currentQuote, from: topController)
                            }
                        }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.black)
                                        .frame(width: 56, height: 56)
                                    
                                    Image(systemName: "arrowshape.turn.up.right.fill")
                                        .font(.title3)
                                        .foregroundColor(.white)
                                }
                                Text("Share")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top, 10)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(UIColor.systemBackground).opacity(0.95))
                    .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: 15)
            )
            .padding(24)
            .scaleEffect(animateIn ? 1.0 : 0.8)
            .opacity(animateIn ? 1.0 : 0)
        }
        .onAppear {
            currentQuote = initialQuote
            fetchAIQuote()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animateIn = true
            }
        }
        .onChange(of: subscriptionManager.isProUser) { _, isPro in
            guard isPro, !isLoading else { return }
            errorMessage = nil
            fetchAIQuote()
        }
        .onChange(of: showUpgradeSheet) { _, isPresented in
            guard !isPresented, subscriptionManager.isProUser, !isLoading else { return }
            errorMessage = nil
            fetchAIQuote()
        }
        .sheet(isPresented: $showUpgradeSheet) {
            UpgradePlanView()
        }
    }
    
    private func fetchAIQuote() {
        // Check subscription status first
        guard subscriptionManager.isProUser else {
            isLoading = false
            needsSubscription = true
            errorMessage = localization.string(for: "dailyQuote.subscriptionRequired")
            return
        }

        needsSubscription = false
        isLoading = true
        Task {
            do {
                let aiQuote = try await KimiService.shared.generateGeneralDailyQuote()

                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.currentQuote = aiQuote
                        self.isLoading = false
                        self.needsSubscription = false
                        self.isSaved = favoritesManager.isSaved(aiQuote)
                    }
                }
            } catch {
                await MainActor.run {
                    if let kimiError = error as? KimiServiceError,
                       case .subscriptionRequired = kimiError {
                        self.needsSubscription = true
                        self.errorMessage = localization.string(for: "dailyQuote.subscriptionRequired")
                    } else {
                        self.errorMessage = "Unable to reach the AI, but here's a thought for you anyway."
                    }
                    self.isLoading = false
                }
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            animateIn = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
}

#Preview {
    DailyQuoteOverlay(
        initialQuote: "True power is not being able to conquer others, but being able to conquer yourself.",
        isPresented: .constant(true)
    )
}
