import Foundation
import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    @Published var userId: String = ""
    @Published var password: String = ""
    @Published var isPasswordVisible: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showSignUp: Bool = false
    
    private let authService = AuthService.shared
    
    var isValid: Bool {
        !userId.isEmpty && !password.isEmpty
    }
    
    func signIn() async {
        guard isValid else { return }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Try to sign in
        let success = await authService.signIn(id: userId, password: password)
        
        if success {
            await MainActor.run {
                isLoading = false
            }
        } else {
            await MainActor.run {
                isLoading = false
                errorMessage = authService.errorMessage ?? "Authentication failed"
            }
        }
    }
    

}
