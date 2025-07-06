import SwiftUI

struct PasswordRecoveryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PasswordRecoveryViewModel()
    @State private var phoneNumber = ""
    @State private var resetCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var currentStep: RecoveryStep = .phoneNumber
    
    enum RecoveryStep {
        case phoneNumber
        case verificationCode
        case newPassword
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Password Recovery")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Reset your password using your phone number")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 50)
                
                // Progress indicator
                HStack(spacing: 20) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(getStepColor(for: index))
                            .frame(width: 12, height: 12)
                    }
                }
                .padding(.horizontal)
                
                // Content based on current step
                switch currentStep {
                case .phoneNumber:
                    phoneNumberStep
                case .verificationCode:
                    verificationCodeStep
                case .newPassword:
                    newPasswordStep
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .alert("Success", isPresented: $viewModel.showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your password has been reset successfully!")
            }
        }
    }
    
    private var phoneNumberStep: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Phone Number")
                    .font(.headline)
                
                TextField("Enter your phone number", text: $phoneNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.phonePad)
            }
            
            Button(action: {
                Task {
                    await viewModel.requestResetCode(phoneNumber: phoneNumber)
                    if !viewModel.showError {
                        currentStep = .verificationCode
                    }
                }
            }) {
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
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(phoneNumber.isEmpty || viewModel.isLoading)
        }
    }
    
    private var verificationCodeStep: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Verification Code")
                    .font(.headline)
                
                Text("Enter the 6-digit code sent to your phone")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("Enter 6-digit code", text: $resetCode)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                    .onChange(of: resetCode) { newValue in
                        if newValue.count > 6 {
                            resetCode = String(newValue.prefix(6))
                        }
                    }
            }
            
            HStack {
                Button("Back") {
                    currentStep = .phoneNumber
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(10)
                
                Button(action: {
                    if resetCode.count == 6 {
                        currentStep = .newPassword
                    }
                }) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(resetCode.count == 6 ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(resetCode.count != 6)
            }
        }
    }
    
    private var newPasswordStep: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("New Password")
                    .font(.headline)
                
                SecureField("Enter new password", text: $newPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Password")
                    .font(.headline)
                
                SecureField("Confirm new password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            HStack {
                Button("Back") {
                    currentStep = .verificationCode
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(10)
                
                Button(action: {
                    Task {
                        await viewModel.resetPassword(
                            phoneNumber: phoneNumber,
                            resetCode: resetCode,
                            newPassword: newPassword
                        )
                    }
                }) {
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
                    .background(canResetPassword ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!canResetPassword || viewModel.isLoading)
            }
        }
    }
    
    private var canResetPassword: Bool {
        !newPassword.isEmpty && 
        !confirmPassword.isEmpty && 
        newPassword == confirmPassword && 
        newPassword.count >= 6
    }
    
    private func getStepColor(for index: Int) -> Color {
        let stepIndex: Int
        switch currentStep {
        case .phoneNumber: stepIndex = 0
        case .verificationCode: stepIndex = 1
        case .newPassword: stepIndex = 2
        }
        
        return index <= stepIndex ? .blue : .gray.opacity(0.3)
    }
}

#Preview {
    PasswordRecoveryView()
} 