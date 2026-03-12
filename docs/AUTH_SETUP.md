# Auth Setup Guide

Three sign-in methods: Apple, Google, Email/Password.

## Current State

- Apple Sign-In: fully wired up in `AuthManager.swift` and `SignInView.swift`
- Google Sign-In: not started
- Email/Password: not started

## 1. Google Cloud Console Setup (Free)

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project (or use an existing one)
3. Go to **APIs & Services → OAuth consent screen**
   - Set up consent screen (External)
   - Add scopes: `openid`, `email`, `profile`
4. Go to **APIs & Services → Credentials**
5. Create **OAuth 2.0 Client ID** — type: **Web application**
   - Add Authorized Redirect URI: `https://pvticprgzlifpsrkgijs.supabase.co/auth/v1/callback`
   - Save the **Client ID** and **Client Secret**
6. Create **another OAuth 2.0 Client ID** — type: **iOS**
   - Enter the app's Bundle ID
   - Save the **iOS Client ID**

## 2. Supabase Dashboard Setup

1. Go to **Authentication → Providers → Google**
2. Enable the Google provider
3. Paste the **Web Client ID** and **Client Secret** from step 1
4. Enable **"Skip nonce checks"** (required for iOS native Google Sign-In)

## 3. Xcode Setup

### Google Sign-In Package
- Add Swift Package: `https://github.com/google/GoogleSignIn-iOS` (v9.1.0)
- Add iOS Client ID to Info.plist as `GIDClientID`
- Add a URL scheme matching the reversed iOS Client ID (e.g., `com.googleusercontent.apps.YOUR_CLIENT_ID` reversed)

### No extra setup needed for Apple or Email/Password

## 4. Code Changes

### AuthManager.swift — Add methods:

| Method | Supabase API |
|---|---|
| `signIn(email:password:)` | `supabase.auth.signIn(email:password:)` |
| `signUp(email:password:)` | `supabase.auth.signUp(email:password:)` |
| `handleSignInWithGoogle()` | `GIDSignIn.sharedInstance.signIn(withPresenting:)` → extract `idToken` + `accessToken` → `supabase.auth.signInWithIdToken(credentials: .init(provider: .google, idToken:, accessToken:))` |

### SignInView.swift — Add UI:

- Sign in with Apple button (already exists)
- Sign in with Google button
- Divider ("or")
- Email/password form with sign-in / sign-up toggle
- Error messages per method
- After email sign-up: "Check your inbox" confirmation screen

## 5. Email Confirmation

- Enabled by default in Supabase (standard practice)
- On sign-up, session is nil until user clicks confirmation link in email
- Show a "Check your inbox to verify your email" screen after sign-up
- Include a "Resend email" button
- Supabase handles the confirmation email automatically
