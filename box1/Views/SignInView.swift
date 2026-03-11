import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.tint)
                Text("box1")
                    .font(.largeTitle.bold())
                Text("Track your Pokemon collection")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(32)
            .glassEffect(.regular, in: .rect(cornerRadius: 20))

            Spacer()

            VStack(spacing: 16) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = authManager.generateNonce()
                } onCompletion: { result in
                    Task {
                        do {
                            try await authManager.handleSignInWithApple(result)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
                .signInWithAppleButtonStyle(.whiteOutline)
                .frame(height: 50)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }
}
