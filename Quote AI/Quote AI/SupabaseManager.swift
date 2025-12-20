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
        } catch {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    // Sign in with Google
    func signInWithGoogle(presentingViewController: UIViewController) async throws {
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
    }

    // Sign in with Apple
    func signInWithApple() async throws {
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
    }

    // Sign out
    func signOut() async throws {
        try await client.auth.signOut()
        GIDSignIn.sharedInstance.signOut()
        self.currentUser = nil
        self.isAuthenticated = false
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
            .order("updated_at", ascending: false)
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
