import SwiftUI

struct PasswordRecoveryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PasswordRecoveryViewModel()
    @State private var email = ""
    @State private var resetCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var currentStep: RecoveryStep = .requestCode
    
    enum RecoveryStep {
        case requestCode
        case enterCode
        case newPassword
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Password Recovery")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(getStepDescription())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Form
                VStack(spacing: 20) {
                    switch currentStep {
                    case .requestCode:
                        requestCodeView
                    case .enterCode:
                        enterCodeView
                    case .newPassword:
                        newPasswordView
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Password Recovery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var requestCodeView: some View {
        VStack(spacing: 16) {
            CustomTextField(
                text: $email,
                placeholder: "Enter your email address",
                icon: "envelope",
                keyboardType: .emailAddress
            )
            
            Button(action: requestResetCode) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Send Reset Code")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(!email.isEmpty ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(email.isEmpty || viewModel.isLoading)
        }
    }
    
    private var enterCodeView: some View {
        VStack(spacing: 16) {
            Text("Enter the 6-digit code sent to \(email)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { index in
                    VerificationCodeDigitField(
                        text: $resetCode,
                        index: index
                    )
                }
            }
            
            Button(action: verifyResetCode) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Verify Code")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(resetCode.count == 6 ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(resetCode.count != 6 || viewModel.isLoading)
            
            Button(action: requestResetCode) {
                Text("Resend Code")
                    .foregroundColor(.blue)
            }
            .disabled(viewModel.isLoading)
        }
    }
    
    private var newPasswordView: some View {
        VStack(spacing: 16) {
            CustomTextField(
                text: $newPassword,
                placeholder: "New Password",
                icon: "lock",
                isSecure: true
            )
            
            CustomTextField(
                text: $confirmPassword,
                placeholder: "Confirm New Password",
                icon: "lock",
                isSecure: true
            )
            
            Button(action: resetPassword) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Reset Password")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isPasswordFormValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!isPasswordFormValid || viewModel.isLoading)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getStepDescription() -> String {
        switch currentStep {
        case .requestCode:
            return "Enter your email address to receive a password reset code"
        case .enterCode:
            return "Enter the 6-digit code sent to your email"
        case .newPassword:
            return "Create a new password for your account"
        }
    }
    
    private var isPasswordFormValid: Bool {
        return !newPassword.isEmpty && !confirmPassword.isEmpty && newPassword == confirmPassword && newPassword.count >= 6
    }
    
    private func requestResetCode() {
        Task {
            await viewModel.requestResetCode(email: email)
            if viewModel.showSuccess {
                currentStep = .enterCode
            }
        }
    }
    
    private func verifyResetCode() {
        // For demo purposes, accept any 6-digit code
        currentStep = .newPassword
    }
    
    private func resetPassword() {
        Task {
            await viewModel.resetPassword(
                email: email,
                resetCode: resetCode,
                newPassword: newPassword
            )
            if viewModel.showSuccess {
                dismiss()
            }
        }
    }
}

#Preview {
    PasswordRecoveryView()
} 