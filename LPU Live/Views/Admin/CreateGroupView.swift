import SwiftUI
import FirebaseFirestore

struct CreateGroupView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
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
                        TextField("Group Name (e.g., K22GX - INT315)", text: $groupName)
                        TextField("Description", text: $description)
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
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showUserSelection) {
                UserSelectionView(preselectedIds: selectedMemberIds) { selectedIds in
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
                // Use selected member IDs directly
                let membersList = Array(selectedMemberIds)
                
                // No validation needed - users were already validated when selected
                
                // Always include the creator
                var allMembers = membersList
                if let currentUserId = AuthService.shared.currentUser?.userId {
                    if !allMembers.contains(currentUserId) {
                        allMembers.append(currentUserId)
                    }
                }
                
                let newGroup = Group(
                    name: groupName,
                    description: description,
                    createdBy: AuthService.shared.currentUser?.userId ?? "unknown",
                    members: allMembers,
                    teachers: [],
                    createdAt: Date(),
                    lastMessage: nil,
                    lastMessageTime: Date(), // Set initial time to avoid query issues
                    logoUrl: "group_default_logo"
                )
                
                try Firestore.firestore().collection(FirebaseConfig.Collections.groups).addDocument(from: newGroup)
                
                await MainActor.run {
                    isLoading = false
                    presentationMode.wrappedValue.dismiss()
                }
                
                print("✅ Group created successfully: \(groupName) with \(allMembers.count) members")
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
