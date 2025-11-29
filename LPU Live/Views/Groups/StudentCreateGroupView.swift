import SwiftUI
import FirebaseFirestore

struct StudentCreateGroupView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authService: AuthService
    @State private var groupName = ""
    @State private var description = ""
    @State private var selectedMemberIds: Set<String> = []
    @State private var showUserSelection = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.background.ignoresSafeArea()
                
                Form {
                    Section(header: Text("Group Details")) {
                        TextField("Group Name", text: $groupName)
                        TextField("Description (optional)", text: $description)
                    }
                    
                    Section(header: Text("Members (\(selectedMemberIds.count) selected)")) {
                        Button(action: {
                            showUserSelection = true
                        }) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(DesignSystem.Colors.primary)
                                Text("Select Members")
                                    .foregroundColor(themeManager.text)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    Section {
                        Button(action: createGroup) {
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Create Group")
                                    .fontWeight(.bold)
                                    .foregroundColor(DesignSystem.Colors.primary)
                            }
                        }
                        .disabled(groupName.isEmpty || isLoading)
                    }
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showUserSelection) {
                StudentUserSelectionView(preselectedIds: selectedMemberIds) { selectedIds in
                    selectedMemberIds = selectedIds
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    func createGroup() {
        guard !groupName.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let membersList = Array(selectedMemberIds)
                
                // Always include the creator
                var allMembers = membersList
                if let currentUserId = authService.currentUser?.userId {
                    if !allMembers.contains(currentUserId) {
                        allMembers.append(currentUserId)
                    }
                }
                
                let newGroup = Group(
                    name: groupName,
                    description: description,
                    createdBy: authService.currentUser?.userId ?? "unknown",
                    members: allMembers,
                    teachers: [],
                    createdAt: Date(),
                    lastMessage: nil,
                    lastMessageTime: Date(),
                    isPersonal: true,  // Mark as personal group
                    logoUrl: "group_default_logo"
                )
                
                try Firestore.firestore().collection(FirebaseConfig.Collections.groups).addDocument(from: newGroup)
                
                await MainActor.run {
                    isLoading = false
                    presentationMode.wrappedValue.dismiss()
                }
                
                print("✅ Personal group created: \(groupName) with \(allMembers.count) members")
            } catch {
                print("❌ Error creating group: \(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = "Failed to create group. Please try again."
                    isLoading = false
                }
            }
        }
    }
}

// Student-only user selection
struct StudentUserSelectionView: View {
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
        // Filter to students only
        let students = allUsers.filter { $0.role == .student }
        
        if searchText.isEmpty {
            return students
        }
        return students.filter { user in
            user.name.lowercased().contains(searchText.lowercased()) ||
            user.userId.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search students...", text: $searchText)
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
            .navigationTitle("Select Students")
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
