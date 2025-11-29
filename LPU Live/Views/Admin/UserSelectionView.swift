import SwiftUI
import FirebaseFirestore

struct UserSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var themeManager: ThemeManager
    @State private var searchText = ""
    @State private var allUsers: [User] = []
    @State private var selectedUserIds: Set<String>
    @State private var isLoading = false
    
    let onConfirm: (Set<String>) -> Void
    
    init(preselectedIds: Set<String> = [], onConfirm: @escaping (Set<String>) -> Void) {
        self._selectedUserIds = State(initialValue: preselectedIds)
        self.onConfirm = onConfirm
    }
    
    var filteredUsers: [User] {
        // Filter out admin users
        let nonAdminUsers = allUsers.filter { $0.role != .admin }
        
        if searchText.isEmpty {
            return nonAdminUsers
        }
        return nonAdminUsers.filter { user in
            user.name.lowercased().contains(searchText.lowercased()) ||
            user.userId.lowercased().contains(searchText.lowercased())
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
                        TextField("Search users...", text: $searchText)
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
                    } else {
                        // User List
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(filteredUsers) { user in
                                    UserSelectionRow(
                                        user: user,
                                        isSelected: selectedUserIds.contains(user.userId)
                                    ) { isSelected in
                                        if isSelected {
                                            selectedUserIds.insert(user.userId)
                                        } else {
                                            selectedUserIds.remove(user.userId)
                                        }
                                    }
                                    Divider().background(Color.gray.opacity(0.2))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Members")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    onConfirm(selectedUserIds)
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .onAppear {
                fetchUsers()
            }
        }
    }
    
    private func fetchUsers() {
        isLoading = true
        Task {
            do {
                let users = try await UserService().fetchAllUsers()
                await MainActor.run {
                    self.allUsers = users
                    self.isLoading = false
                }
            } catch {
                print("Error fetching users: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

struct UserSelectionRow: View {
    let user: User
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            HStack(spacing: 16) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? DesignSystem.Colors.primary : .gray)
                    .font(.title3)
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(DesignSystem.Fonts.body())
                        .foregroundColor(themeManager.text)
                    
                    HStack {
                        Text(user.userId)
                            .font(.caption)
                            .foregroundColor(themeManager.textSecondary)
                        
                        Text("•")
                            .foregroundColor(themeManager.textSecondary)
                        
                        Text(user.role.title)
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(themeManager.background)
        }
    }
}
