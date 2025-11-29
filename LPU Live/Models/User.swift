import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var name: String
    var email: String
    var role: UserRole
    var department: String?
    var profileImageUrl: String?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case name
        case email
        case role
        case department
        case profileImageUrl
        case createdAt
    }
}
