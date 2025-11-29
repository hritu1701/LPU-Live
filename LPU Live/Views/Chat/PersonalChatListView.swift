import SwiftUI

struct PersonalChatListView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authService: AuthService
    @State private var searchText = ""
    @State private var students: [User] = []
    @State private var isLoading = false
    @State private var isCreatingDM = false
    @State private var selectedDMGroup: Group?
    @State private var showDMChat = false
    
    var filteredStudents: [User] {
        if searchText.isEmpty {
            return students
        }
        return students.filter { 
            $0.name.lowercased().contains(searchText.lowercased()) ||
            $0.userId.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        ZStack {
            themeManager.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                Text("Chats")
                    .font(DesignSystem.Fonts.header())
                    .foregroundColor(themeManager.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search students...", text: $searchText)
                        .foregroundColor(themeManager.text)
                }
                .padding()
                .background(themeManager.card)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if filteredStudents.isEmpty {
                    // Empty State
                    VStack {
                        Spacer()
                        
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No Students Found")
                            .font(DesignSystem.Fonts.header(20))
                            .foregroundColor(themeManager.text)
                            .padding(.top)
                        
                        Text("Search for students to start chatting")
                            .font(DesignSystem.Fonts.body())
                            .foregroundColor(themeManager.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Spacer()
                    }
                } else {
                    // List
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredStudents) { student in
                                Button(action: {
                                    openDirectMessage(with: student)
                                }) {
                                    HStack(spacing: 16) {
                                        // Avatar
                                        if let avatar = student.profileImageUrl, !avatar.isEmpty {
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
                                                    Text(String(student.name.prefix(1)))
                                                        .font(.title3)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(DesignSystem.Colors.primary)
                                                )
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(student.name)
                                                .font(DesignSystem.Fonts.body(16))
                                                .fontWeight(.semibold)
                                                .foregroundColor(themeManager.text)
                                            
                                            Text(student.userId)
                                                .font(.caption)
                                                .foregroundColor(themeManager.textSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if isCreatingDM {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        }
                                    }
                                    .padding()
                                    .background(themeManager.background)
                                }
                                .disabled(isCreatingDM)
                                Divider().background(Color.gray.opacity(0.2))
                            }
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $showDMChat) {
            if let dmGroup = selectedDMGroup {
                ChatView(viewModel: ChatViewModel(group: dmGroup, currentUser: authService.currentUser))
            }
        }
        .onAppear {
            fetchStudents()
        }
    }
    
    private func openDirectMessage(with student: User) {
        guard let currentUserId = authService.currentUser?.userId else { return }
        
        isCreatingDM = true
        Task {
            do {
                let dmGroup = try await ChatService().createOrGetDirectMessage(
                    currentUserId: currentUserId,
                    otherUserId: student.userId,
                    otherUserName: student.name
                )
                
                await MainActor.run {
                    selectedDMGroup = dmGroup
                    showDMChat = true
                    isCreatingDM = false
                }
            } catch {
                print("Error creating/opening DM: \(error.localizedDescription)")
                await MainActor.run {
                    isCreatingDM = false
                }
            }
        }
    }
    
    private func fetchStudents() {
        isLoading = true
        Task {
            do {
                let allUsers = try await UserService().fetchAllUsers()
                await MainActor.run {
                    // Filter to students only, excluding current user
                    self.students = allUsers.filter { 
                        $0.role == .student && $0.userId != authService.currentUser?.userId 
                    }
                    self.isLoading = false
                }
            } catch {
                print("Error fetching students: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}
