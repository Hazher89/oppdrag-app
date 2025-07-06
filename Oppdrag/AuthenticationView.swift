//
//  AuthenticationView.swift
//  Oppdrag
//
//  Created by Hazher  on 05/07/2025.
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var confirmPassword = ""
    @State private var showPasswordRecovery = false
    @State private var verificationCode = ""
    @State private var showVerificationStep = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("DriveDispatch")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(getHeaderText())
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                if showVerificationStep {
                    verificationStepView
                } else {
                    authenticationStepView
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
    
    private var authenticationStepView: some View {
        VStack(spacing: 20) {
            // Form
            VStack(spacing: 16) {
                CustomTextField(
                    text: $email,
                    placeholder: "Email Address",
                    icon: "envelope",
                    keyboardType: .emailAddress
                )
                
                if isSignUp {
                    CustomTextField(
                        text: $name,
                        placeholder: "Full Name",
                        icon: "person"
                    )
                }
                
                if !isSignUp {
                    CustomTextField(
                        text: $password,
                        placeholder: "Password",
                        icon: "lock",
                        isSecure: true
                    )
                }
            }
            
            // Action Button
            Button(action: handleSendVerificationCode) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text(isSignUp ? "Send Verification Code" : "Send Login Code")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!isFormValid || isLoading)
            
            // Toggle Sign Up/Login
            Button(action: { isSignUp.toggle() }) {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .foregroundColor(.blue)
            }
            
            if !isSignUp {
                Button(action: { showPasswordRecovery = true }) {
                    Text("Forgot Password?")
                        .foregroundColor(.blue)
                }
            }
            
            // Error/Success Messages
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            
            if let successMessage = successMessage {
                Text(successMessage)
                    .foregroundColor(.green)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var verificationStepView: some View {
        VStack(spacing: 20) {
            // Verification Code Input
            VStack(spacing: 16) {
                Text("Enter Verification Code")
                    .font(.headline)
                
                Text("We sent a 6-digit code to \(email)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 12) {
                    ForEach(0..<6, id: \.self) { index in
                        VerificationCodeDigitField(
                            text: $verificationCode,
                            index: index
                        )
                    }
                }
                
                if isSignUp {
                    CustomTextField(
                        text: $password,
                        placeholder: "Create Password",
                        icon: "lock",
                        isSecure: true
                    )
                    
                    CustomTextField(
                        text: $confirmPassword,
                        placeholder: "Confirm Password",
                        icon: "lock",
                        isSecure: true
                    )
                }
            }
            
            // Verify Button
            Button(action: handleVerifyCode) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Verify Code")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isVerificationFormValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!isVerificationFormValid || isLoading)
            
            // Back Button
            Button(action: { 
                showVerificationStep = false
                verificationCode = ""
                errorMessage = nil
                successMessage = nil
            }) {
                Text("Back to Email")
                    .foregroundColor(.blue)
            }
            
            // Resend Code
            Button(action: handleSendVerificationCode) {
                Text("Resend Code")
                    .foregroundColor(.blue)
            }
            .disabled(isLoading)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getHeaderText() -> String {
        if showVerificationStep {
            return "Verify Your Email"
        } else if isSignUp {
            return "Create your account"
        } else {
            return "Welcome back"
        }
    }
    
    private var isFormValid: Bool {
        if isSignUp {
            return !name.isEmpty && !email.isEmpty && isValidEmail(email)
        } else {
            return !email.isEmpty && isValidEmail(email)
        }
    }
    
    private var isVerificationFormValid: Bool {
        if isSignUp {
            return verificationCode.count == 6 && !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword
        } else {
            return verificationCode.count == 6
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func handleSendVerificationCode() {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                let type = isSignUp ? "registration" : "login"
                let response = try await authManager.sendVerificationCode(email: email, type: type)
                
                await MainActor.run {
                    isLoading = false
                    successMessage = response.message
                    showVerificationStep = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func handleVerifyCode() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let type = isSignUp ? "registration" : "login"
                try await authManager.verifyCode(
                    email: email,
                    verificationCode: verificationCode,
                    type: type,
                    name: isSignUp ? name : nil,
                    password: isSignUp ? password : nil
                )
                
                await MainActor.run {
                    isLoading = false
                    // Authentication successful - user will be logged in automatically
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct VerificationCodeDigitField: View {
    @Binding var text: String
    let index: Int
    
    var body: some View {
        TextField("", text: Binding(
            get: {
                if index < text.count {
                    return String(text[text.index(text.startIndex, offsetBy: index)])
                }
                return ""
            },
            set: { newValue in
                if newValue.count <= 1 {
                    if newValue.isEmpty {
                        if text.count > index {
                            text.remove(at: text.index(text.startIndex, offsetBy: index))
                        }
                    } else {
                        if index < text.count {
                            text.remove(at: text.index(text.startIndex, offsetBy: index))
                            text.insert(newValue.first!, at: text.index(text.startIndex, offsetBy: index))
                        } else {
                            text.append(newValue)
                        }
                    }
                }
            }
        ))
        .keyboardType(.numberPad)
        .multilineTextAlignment(.center)
        .frame(width: 50, height: 50)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .onChange(of: text) { _, newValue in
            if newValue.count > 6 {
                text = String(newValue.prefix(6))
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
} 