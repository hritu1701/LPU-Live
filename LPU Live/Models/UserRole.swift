import Foundation

enum UserRole: String, Codable, CaseIterable {
    case admin
    case teacher
    case student
    
    var title: String {
        switch self {
        case .admin: return "Admin"
        case .teacher: return "Teacher"
        case .student: return "Student"
        }
    }
    
    var icon: String {
        switch self {
        case .admin: return "shield.fill"
        case .teacher: return "book.fill"
        case .student: return "graduationcap.fill"
        }
    }
}
