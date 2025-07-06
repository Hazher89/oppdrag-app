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
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var name = ""
    @State private var confirmPassword = ""
    @State private var showPasswordRecovery = false
    
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
                    
                    Text(isSignUp ? "Create your account" : "Welcome back")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                // Form
                VStack(spacing: 20) {
                    if isSignUp {
                        CustomTextField(
                            text: $name,
                            placeholder: "Full Name",
                            icon: "person.fill"
                        )
                    }
                    
                    CustomTextField(
                        text: $phoneNumber,
                        placeholder: "Phone Number",
                        icon: "phone.fill",
                        keyboardType: .phonePad
                    )
                    
                    CustomTextField(
                        text: $password,
                        placeholder: "Password",
                        icon: "lock.fill",
                        isSecure: true
                    )
                    
                    if isSignUp {
                        CustomTextField(
                            text: $confirmPassword,
                            placeholder: "Confirm Password",
                            icon: "lock.fill",
                            isSecure: true
                        )
                    }
                }
                
                // Error Message
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                // Action Button
                Button(action: handleAuthentication) {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isSignUp ? "Create Account" : "Sign In")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(authManager.isLoading || !isFormValid)
                .opacity(isFormValid ? 1.0 : 0.6)
                
                // Forgot Password Button (only show on sign in)
                if !isSignUp {
                    Button(action: {
                        showPasswordRecovery = true
                    }) {
                        Text("Forgot Password?")
                            .foregroundColor(.blue)
                            .font(.subheadline)
                    }
                    .padding(.top, 8)
                }
                
                // Toggle Sign In/Sign Up
                Button(action: { isSignUp.toggle() }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding(.horizontal, 30)
            .padding(.top, 50)
            .sheet(isPresented: $showPasswordRecovery) {
                PasswordRecoveryView()
            }
        }
    }
    
    private var isFormValid: Bool {
        if isSignUp {
            return !name.isEmpty && !phoneNumber.isEmpty && !password.isEmpty && 
                   !confirmPassword.isEmpty && password == confirmPassword
        } else {
            return !phoneNumber.isEmpty && !password.isEmpty
        }
    }
    
    private func handleAuthentication() {
        if isSignUp {
            authManager.signUp(phoneNumber: phoneNumber, name: name, password: password)
        } else {
            authManager.signIn(phoneNumber: phoneNumber, password: password)
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

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
} 