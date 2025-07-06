import Foundation

@MainActor
class PasswordRecoveryViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var showError = false
    @Published var showSuccess = false
    @Published var errorMessage = ""
    
    private let apiService = APIService.shared
    
    func requestResetCode(phoneNumber: String) async {
        isLoading = true
        showError = false
        
        do {
            let response = try await apiService.forgotPassword(phoneNumber: phoneNumber)
            print("Reset code sent: \(response.resetCode)") // For testing - remove in production
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func resetPassword(phoneNumber: String, resetCode: String, newPassword: String) async {
        isLoading = true
        showError = false
        
        do {
            let response = try await apiService.resetPassword(
                phoneNumber: phoneNumber,
                resetCode: resetCode,
                newPassword: newPassword
            )
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
} 