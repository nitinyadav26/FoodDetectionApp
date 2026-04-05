import SwiftUI

struct LoginView: View {
    @ObservedObject var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isCreateAccount = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "fork.knife.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.green)

            Text("FoodSense")
                .font(.largeTitle)
                .bold()

            Text(isCreateAccount ? "Create Account" : "Sign In")
                .font(.title2)
                .foregroundColor(.secondary)

            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                SecureField("Password", text: $password)
                    .textContentType(isCreateAccount ? .newPassword : .password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            Button(action: {
                handleEmailAuth()
            }) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                } else {
                    Text(isCreateAccount ? "Create Account" : "Sign In")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .disabled(isProcessing || email.isEmpty || password.isEmpty)
            .padding(.horizontal)

            Button(action: {
                isCreateAccount.toggle()
            }) {
                Text(isCreateAccount ? "Already have an account? Sign In" : "Don't have an account? Create one")
                    .font(.footnote)
                    .foregroundColor(.green)
            }

            Divider()
                .padding(.horizontal, 40)

            Button(action: {
                handleAnonymousAuth()
            }) {
                Text("Continue as Guest")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
            .disabled(isProcessing)
            .padding(.horizontal)

            Spacer()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
    }

    private func handleEmailAuth() {
        isProcessing = true
        Task {
            do {
                if isCreateAccount {
                    try await authManager.createAccount(email: email, password: password)
                } else {
                    try await authManager.signInWithEmail(email: email, password: password)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            await MainActor.run {
                isProcessing = false
            }
        }
    }

    private func handleAnonymousAuth() {
        isProcessing = true
        Task {
            do {
                try await authManager.signInAnonymously()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
            await MainActor.run {
                isProcessing = false
            }
        }
    }
}
