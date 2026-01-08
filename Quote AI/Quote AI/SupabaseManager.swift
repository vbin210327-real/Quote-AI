//
//  SupabaseManager.swift
//  Quote AI
//
//  Manages Supabase authentication
//

import Foundation
import Combine
import Supabase
import GoogleSignIn
import AuthenticationServices

// Apple Sign In Coordinator - Bridges delegate callbacks to async/await
class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<ASAuthorization, Error>?
    private weak var presentingWindow: UIWindow?

    init(window: UIWindow?) {
        self.presentingWindow = window
        super.init()
    }

    func signIn() async throws -> ASAuthorization {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation

            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: - ASAuthorizationControllerDelegate

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation?.resume(returning: authorization)
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    // MARK: - ASAuthorizationControllerPresentationContextProviding

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return presentingWindow ?? UIWindow()
    }
}

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    @Published var currentUser: User?
    @Published var isAuthenticated = false

    var isCurrentUserAnonymous: Bool {
        currentUser?.isAnonymous ?? false
    }

    let client: SupabaseClient
    private var appleSignInCoordinator: AppleSignInCoordinator?

    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
            supabaseKey: SupabaseConfig.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
        
        Task {
            await checkSession()
        }
    }
    
    // Check if user has an active session
    func checkSession() async {
        do {
            let session = try await client.auth.session
            self.currentUser = session.user
            self.isAuthenticated = true
            syncSharedSession(session)

            // Link RevenueCat to Supabase user ID (ensures purchases are linked)
            await SubscriptionManager.shared.login(userId: session.user.id.uuidString)

            // Sync data from cloud on app launch to ensure cross-device consistency
            await syncFromCloud()
        } catch {
            self.currentUser = nil
            self.isAuthenticated = false
            syncSharedSession(nil)
        }
    }
    
    // Sign in with Google
    func signInWithGoogle(presentingViewController: UIViewController) async throws {
        let previousUser = currentUser
        // Initialize Google Sign-In with iOS Client ID only
        let config = GIDConfiguration(clientID: SupabaseConfig.googleIOSClientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Start Google Sign-In flow
        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: presentingViewController
        )
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "GoogleSignIn", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Failed to get ID token"
            ])
        }
        
        // Get access token
        let accessToken = result.user.accessToken.tokenString
        
        // Sign in to Supabase with Google tokens
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .google,
                idToken: idToken,
                accessToken: accessToken
            )
        )

        self.currentUser = session.user
        self.isAuthenticated = true
        syncSharedSession(session)

        // Link RevenueCat to Supabase user ID
        await SubscriptionManager.shared.login(userId: session.user.id.uuidString)

        if previousUser?.isAnonymous == true {
            await migrateAnonymousData(from: previousUser?.id.uuidString)
        }

        // Sync data from cloud after login
        await syncFromCloud()
    }

    // Sign in with Apple
    func signInWithApple() async throws {
        let previousUser = currentUser
        // Get the key window for presenting the Apple Sign In sheet
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            throw NSError(domain: "AppleSignIn", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Unable to find window for presentation"
            ])
        }

        // Create coordinator and keep strong reference during sign-in
        let coordinator = AppleSignInCoordinator(window: window)
        self.appleSignInCoordinator = coordinator

        defer {
            self.appleSignInCoordinator = nil
        }

        // Perform Apple Sign In
        let authorization = try await coordinator.signIn()

        // Extract credentials from authorization
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = appleIDCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            throw NSError(domain: "AppleSignIn", code: -2, userInfo: [
                NSLocalizedDescriptionKey: "Failed to get Apple ID credentials"
            ])
        }

        // Sign in to Supabase with Apple token
        let session = try await client.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: identityToken
            )
        )

        self.currentUser = session.user
        self.isAuthenticated = true
        syncSharedSession(session)

        // Link RevenueCat to Supabase user ID
        await SubscriptionManager.shared.login(userId: session.user.id.uuidString)

        if previousUser?.isAnonymous == true {
            await migrateAnonymousData(from: previousUser?.id.uuidString)
        }

        // Sync data from cloud after login
        await syncFromCloud()
    }

    // Sign in anonymously (optional account creation)
    func signInAnonymously() async throws {
        let session = try await client.auth.signInAnonymously()

        self.currentUser = session.user
        self.isAuthenticated = true
        syncSharedSession(session)

        // Link RevenueCat to Supabase user ID
        await SubscriptionManager.shared.login(userId: session.user.id.uuidString)

        // Sync data from cloud after login
        await syncFromCloud()
    }

    // Sign out
    func signOut() async throws {
        do {
            try await client.auth.signOut()
        } catch {
            // Sign out error (safe to ignore if session missing)
        }

        GIDSignIn.sharedInstance.signOut()

        // Logout from RevenueCat
        await SubscriptionManager.shared.logout()

        self.currentUser = nil
        self.isAuthenticated = false
        syncSharedSession(nil)

        // Clear local data on logout
        clearLocalData()
    }

    // Delete account and all associated data
    func deleteAccount() async throws {
        try await client.functions.invoke(
            "delete-account",
            options: FunctionInvokeOptions(method: .post)
        )

        try? await signOut()
    }

    // MARK: - Data Sync

    /// Sync all user data from cloud after login
    private func syncFromCloud() async {
        await UserPreferences.shared.syncFromCloud()
        await FavoriteQuotesManager.shared.syncFromCloud()
    }

    private func migrateAnonymousData(from oldUserId: String?) async {
        guard let oldUserId else { return }

        struct MigrationRequest: Encodable {
            let oldUserId: String
        }

        do {
            try await client.functions.invoke(
                "migrate-account",
                options: FunctionInvokeOptions(
                    method: .post,
                    body: MigrationRequest(oldUserId: oldUserId)
                )
            )
        } catch {
            // Ignore migration errors to avoid blocking sign-in
        }
    }

    /// Clear all local user data on logout
    private func clearLocalData() {
        UserPreferences.shared.clearLocalData()
        FavoriteQuotesManager.shared.clearLocalData()
    }

    private func syncSharedSession(_ session: Session?) {
        let sharedDefaults = UserDefaults(suiteName: SharedConstants.suiteName)
        if let session = session {
            sharedDefaults?.set(session.accessToken, forKey: SharedConstants.Keys.supabaseAccessToken)
        } else {
            sharedDefaults?.removeObject(forKey: SharedConstants.Keys.supabaseAccessToken)
        }
        sharedDefaults?.synchronize()
    }
    
    // MARK: - Conversation Management
    
    /// Create a new conversation
    func createConversation(title: String) async throws -> Conversation {
        guard let userId = currentUser?.id.uuidString.lowercased() else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }
        
        let request = CreateConversationRequest(userId: userId, title: title)
        
        let conversation: Conversation = try await client
            .from("conversations")
            .insert(request)
            .select()
            .single()
            .execute()
            .value
        
        return conversation
    }
    
    /// Fetch all conversations for current user
    func fetchConversations() async throws -> [Conversation] {
        guard let userId = currentUser?.id.uuidString.lowercased() else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }
        
        let conversations: [Conversation] = try await client
            .from("conversations")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return conversations
    }
    
    /// Search conversations by title or message content
    func searchConversations(query: String) async throws -> [Conversation] {
        guard let _ = currentUser?.id else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }
        
        let params = ["search_query": query]
        
        let conversations: [Conversation] = try await client
            .rpc("search_conversations", params: params)
            .execute()
            .value
            
        return conversations
    }
    
    /// Save a message to a conversation
    func saveMessage(conversationId: UUID, content: String, isUser: Bool) async throws -> StoredMessage {
        let request = SaveMessageRequest(
            conversationId: conversationId,
            content: content,
            isUser: isUser
        )
        
        let message: StoredMessage = try await client
            .from("messages")
            .insert(request)
            .select()
            .single()
            .execute()
            .value
        
        // Update conversation's updated_at timestamp
        try await updateConversationTimestamp(conversationId: conversationId)
        
        return message
    }
    
    /// Fetch messages for a conversation
    func fetchMessages(conversationId: UUID) async throws -> [StoredMessage] {
        let messages: [StoredMessage] = try await client
            .from("messages")
            .select()
            .eq("conversation_id", value: conversationId.uuidString)
            .order("timestamp", ascending: true)
            .execute()
            .value
        
        return messages
    }
    
    /// Delete a conversation and all its messages
    func deleteConversation(conversationId: UUID) async throws {
        // Supabase will cascade delete messages if configured properly
        try await client
            .from("conversations")
            .delete()
            .eq("id", value: conversationId.uuidString)
            .execute()
    }
    
    /// Delete a specific message by ID
    func deleteMessage(messageId: UUID) async throws {
        try await client
            .from("messages")
            .delete()
            .eq("id", value: messageId.uuidString)
            .execute()
    }
    
    // MARK: - User Profile Management

    /// Fetch user profile from cloud
    func fetchUserProfile() async throws -> UserProfile? {
        guard let userId = currentUser?.id.uuidString.lowercased() else {
            return nil
        }

        let profiles: [UserProfile] = try await client
            .from("user_profiles")
            .select()
            .eq("user_id", value: userId)
            .limit(1)
            .execute()
            .value

        return profiles.first
    }

    /// Save or update user profile to cloud
    func saveUserProfile(
        name: String?,
        gender: String?,
        profileImageUrl: String?,
        birthYear: Int?,
        quoteTone: String?,
        userFocus: String?,
        userBarrier: String?,
        energyDrain: String?,
        mentalEnergy: Double?,
        chatBackground: String?,
        notificationsEnabled: Bool?,
        notificationHour: Int?,
        notificationMinute: Int?,
        language: String?,
        hasCompletedOnboarding: Bool?
    ) async throws {
        guard let userId = currentUser?.id.uuidString.lowercased() else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }

        let request = UpsertUserProfileRequest(
            userId: userId,
            name: name,
            gender: gender,
            profileImageUrl: profileImageUrl,
            birthYear: birthYear,
            quoteTone: quoteTone,
            userFocus: userFocus,
            userBarrier: userBarrier,
            energyDrain: energyDrain,
            mentalEnergy: mentalEnergy,
            chatBackground: chatBackground,
            language: language,
            hasCompletedOnboarding: hasCompletedOnboarding,
            notificationsEnabled: notificationsEnabled,
            notificationHour: notificationHour,
            notificationMinute: notificationMinute,
            updatedAt: Date()
        )

        try await client
            .from("user_profiles")
            .upsert(request, onConflict: "user_id")
            .execute()
    }

    /// Upload profile image to Supabase Storage
    func uploadProfileImage(imageData: Data) async throws -> String {
        guard let userId = currentUser?.id.uuidString.lowercased() else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }

        var bucketName = "profile-images"
        let fileName = "\(userId)/profile.jpg"

        // Try to list buckets to verify ID and case-sensitivity
        do {
            let buckets = try await client.storage.listBuckets()

            // Try to find a bucket that matches "profile-images" case-insensitively
            if let foundBucket = buckets.first(where: { $0.id.lowercased() == "profile-images" }) {
                bucketName = foundBucket.id
            }
        } catch {
            // Continue with default name if listing fails
        }

        // Upload to storage bucket
        try await client.storage
            .from(bucketName)
            .upload(
                fileName,
                data: imageData,
                options: FileOptions(
                    contentType: "image/jpeg",
                    upsert: true
                )
            )

        // Get public URL
        let publicURL = try client.storage
            .from(bucketName)
            .getPublicURL(path: fileName)

        // Add a timestamp to the URL to bypass any image caching
        let finalURL = "\(publicURL.absoluteString)?t=\(Int(Date().timeIntervalSince1970))"
        return finalURL
    }

    /// Download profile image from URL
    func downloadProfileImage(from urlString: String) async throws -> Data? {
        guard let url = URL(string: urlString) else { return nil }

        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }

    // MARK: - Saved Quotes Management

    /// Fetch all saved quotes from cloud
    func fetchSavedQuotes() async throws -> [CloudSavedQuote] {
        guard let userId = currentUser?.id.uuidString.lowercased() else {
            return []
        }

        let quotes: [CloudSavedQuote] = try await client
            .from("saved_quotes")
            .select()
            .eq("user_id", value: userId)
            .order("saved_at", ascending: false)
            .execute()
            .value

        return quotes
    }

    /// Save a quote to cloud
    func saveQuoteToCloud(content: String) async throws -> CloudSavedQuote {
        guard let userId = currentUser?.id.uuidString.lowercased() else {
            throw NSError(domain: "SupabaseManager", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }

        let request = SaveQuoteRequest(userId: userId, content: content)

        let quote: CloudSavedQuote = try await client
            .from("saved_quotes")
            .insert(request)
            .select()
            .single()
            .execute()
            .value

        return quote
    }

    /// Delete a quote from cloud
    func deleteQuoteFromCloud(quoteId: UUID) async throws {
        try await client
            .from("saved_quotes")
            .delete()
            .eq("id", value: quoteId.uuidString)
            .execute()
    }

    /// Delete a quote by content (for sync purposes)
    func deleteQuoteFromCloud(content: String) async throws {
        guard let userId = currentUser?.id.uuidString.lowercased() else { return }

        try await client
            .from("saved_quotes")
            .delete()
            .eq("user_id", value: userId)
            .eq("content", value: content)
            .execute()
    }

    // MARK: - Private Helpers

    private func updateConversationTimestamp(conversationId: UUID) async throws {
        struct UpdateTimestamp: Codable {
            let updatedAt: Date
            enum CodingKeys: String, CodingKey {
                case updatedAt = "updated_at"
            }
        }
        
        let update = UpdateTimestamp(updatedAt: Date())
        
        try await client
            .from("conversations")
            .update(update)
            .eq("id", value: conversationId.uuidString)
            .execute()
    }
}
