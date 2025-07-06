import Foundation

@MainActor
class PasswordRecoveryViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var showError = false
    @Published var showSuccess = false
    @Published var errorMessage = ""
    
    private let apiService = APIService()
    
    func requestResetCode(email: String) async {
        isLoading = true
        showError = false
        
        do {
            _ = try await apiService.forgotPassword(email: email)
            // print("Reset code sent: \(response.resetCode)") // For testing - remove in production
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func resetPassword(email: String, resetCode: String, newPassword: String) async {
        isLoading = true
        showError = false
        
        do {
            _ = try await apiService.resetPassword(
                email: email,
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