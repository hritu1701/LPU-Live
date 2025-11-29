import SwiftUI
import FirebaseFirestore

struct GroupMembersView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var themeManager: ThemeManager
    
    let group: Group
    @State private var members: [User] = []
    @State private var isLoading = false
    @State private var searchText = ""
    
    var filteredMembers: [User] {
        if searchText.isEmpty {
            return members
        }
        return members.filter {
            $0.name.lowercased().contains(searchText.lowercased()) ||
            $0.userId.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search members...", text: $searchText)
                            .foregroundColor(themeManager.text)
                    }
                    .padding()
                    .background(themeManager.card)
                    .cornerRadius(10)
                    .padding()
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if members.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 50))
                                .foregroundColor(themeManager.textSecondary.opacity(0.5))
                            
                            Text("No members found")
                                .font(DesignSystem.Fonts.header(18))
                                .foregroundColor(themeManager.textSecondary)
                        }
                        Spacer()
                    } else {
                        // Members List
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(filteredMembers) { member in
                                    MemberRow(member: member)
                                    Divider().background(Color.gray.opacity(0.2))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("\(group.name) Members")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                fetchMembers()
            }
        }
    }
    
    private func fetchMembers() {
        isLoading = true
        Task {
            do {
                let users = try await UserService().fetchUsers(byIds: group.members)
                await MainActor.run {
                    self.members = users.sorted { user1, user2 in
                        // Sort by role priority: admin > teacher > student
                        if user1.role != user2.role {
                            if user1.role == .admin { return true }
                            if user2.role == .admin { return false }
                            if user1.role == .teacher { return true }
                            if user2.role == .teacher { return false }
                        }
                        return user1.name < user2.name
                    }
                    self.isLoading = false
                }
            } catch {
                print("Error fetching members: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

struct MemberRow: View {
    let member: User
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar - Use LPU logo for admin
            if member.role == .admin {
                Image("lpu_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else if let avatar = member.profileImageUrl, !avatar.isEmpty {
                Text(avatar)
                    .font(.system(size: 30))
                    .frame(width: 50, height: 50)
                    .background(themeManager.card)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(DesignSystem.Colors.primary.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(String(member.name.prefix(1)))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.primary)
                    )
            }
            
            // User Info - Hide admin details
            VStack(alignment: .leading, spacing: 4) {
                Text(member.role == .admin ? "Admin" : member.name)
                    .font(DesignSystem.Fonts.body(16))
                    .foregroundColor(themeManager.text)
                
                HStack(spacing: 8) {
                    Text(member.role == .admin ? "•••••" : member.userId)
                        .font(.caption)
                        .foregroundColor(themeManager.textSecondary)
                    
                    // Role Badge
                    HStack(spacing: 4) {
                        Image(systemName: member.role.icon)
                            .font(.caption2)
                        Text(member.role.title)
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(roleColor(for: member.role).opacity(0.15))
                    .foregroundColor(roleColor(for: member.role))
                    .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(themeManager.background)
    }
    
    private func roleColor(for role: UserRole) -> Color {
        switch role {
        case .admin:
            return .red
        case .teacher:
            return .blue
        case .student:
            return .green
        }
    }
}
