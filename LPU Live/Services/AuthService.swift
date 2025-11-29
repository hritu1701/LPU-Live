import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    static let shared = AuthService()
    private let db = Firestore.firestore()
    
    init() {
        // Check for existing session
        if let authUser = Auth.auth().currentUser {
            Task {
                await self.fetchUser(userId: authUser.uid)
            }
        }
    }
    
    func signIn(id: String, password: String) async -> Bool {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // Convert ID to email format for Firebase Auth
            let email = "\(id)@lpu.in"
            
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            await fetchUser(userId: result.user.uid)
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
            return true
        } catch let error as NSError {
            DispatchQueue.main.async {
                self.isLoading = false
                
                // Provide specific error messages based on Firebase error codes
                if let errorCode = AuthErrorCode(rawValue: error.code) {
                    switch errorCode {
                    case .userNotFound, .invalidEmail:
                        self.errorMessage = "Enter valid Registration number"
                    case .wrongPassword:
                        self.errorMessage = "Enter valid password"
                    case .networkError:
                        self.errorMessage = "Network error. Please check your connection"
                    case .tooManyRequests:
                        self.errorMessage = "Too many attempts. Please try again later"
                    default:
                        self.errorMessage = error.localizedDescription
                    }
                } else {
                    self.errorMessage = error.localizedDescription
                }
            }
            return false
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.currentUser = nil
                self.isAuthenticated = false
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    // Helper to fetch user profile from Firestore
    func fetchUser(userId: String) async {
        do {
            let snapshot = try await db.collection(FirebaseConfig.Collections.users).document(userId).getDocument()
            
            if snapshot.exists {
                let user = try snapshot.data(as: User.self)
                await MainActor.run {
                    self.currentUser = user
                    self.isAuthenticated = true
                }
            } else {
                // Document does not exist.
                // If this is the currently signed-in user, create a default profile.
                if let authUser = Auth.auth().currentUser, authUser.uid == userId {
                    print("User document missing. Creating default profile...")
                    await createDefaultUser(authUser: authUser)
                } else {
                    print("User document does not exist")
                }
            }
        } catch {
            print("Error fetching user: \(error.localizedDescription)")
        }
    }
    
    private func createDefaultUser(authUser: FirebaseAuth.User) async {
        let email = authUser.email ?? ""
        let regNumber = email.components(separatedBy: "@").first ?? ""
        
        // Determine Role based on ID length
        let role: UserRole
        switch regNumber.count {
        case 4: role = .admin
        case 5: role = .teacher
        case 8: role = .student
        default: role = .student
        }
        
        let newUser = User(
            userId: regNumber,
            name: "Reg: \(regNumber)",
            email: email,
            role: role,
            createdAt: Date()
        )
        
        do {
            try db.collection(FirebaseConfig.Collections.users).document(authUser.uid).setData(from: newUser)
            await MainActor.run {
                self.currentUser = newUser
                self.isAuthenticated = true
            }
            print("Default profile created successfully")
        } catch {
            print("Error creating default profile: \(error.localizedDescription)")
        }
    }
    
    // Temporary function to create a test user (since we don't have a full signup flow yet)

}
