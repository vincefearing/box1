import Foundation
import AuthenticationServices
import CryptoKit
import Supabase

@Observable
final class AuthManager {
    var session: Session?
    var profile: UserProfile?

    var isSignedIn: Bool { session != nil }
    var userId: UUID? { session?.user.id }
    var displayName: String { profile?.displayName ?? "" }

    private var currentNonce: String?

    // MARK: - Session

    func restoreSession() async {
        do {
            session = try await supabase.auth.session
            if isSignedIn { await fetchProfile() }
        } catch {
            session = nil
        }
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        session = nil
        profile = nil
    }

    // MARK: - Sign in with Apple

    func generateNonce() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }

    func handleSignInWithApple(_ result: Result<ASAuthorization, any Error>) async throws {
        let authorization = try result.get()
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8),
              let nonce = currentNonce else {
            throw AuthManagerError.invalidCredential
        }

        session = try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: identityToken, nonce: nonce)
        )

        if let fullName = credential.fullName {
            let name = [fullName.givenName, fullName.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            if !name.isEmpty {
                _ = try? await supabase.auth.update(user: .init(data: ["full_name": .string(name)]))
            }
        }

        await fetchProfile()
    }

    // MARK: - Profile

    func fetchProfile() async {
        guard let userId else { return }
        do {
            profile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
        } catch {
            print("Error fetching profile: \(error)")
        }
    }

    // MARK: - Nonce Helpers

    private func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var random: UInt8 = 0
            _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if random < charset.count {
                result.append(charset[Int(random)])
                remaining -= 1
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

enum AuthManagerError: LocalizedError {
    case invalidCredential

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Invalid sign-in credential"
        }
    }
}
