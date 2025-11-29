import SwiftUI
import FirebaseFirestore

struct PersonalGroupListView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authService: AuthService
    @State private var searchText = ""
    @State private var groups: [Group] = []
    @State private var listener: ListenerRegistration?
    @State private var showCreateGroup = false
    
    var filteredGroups: [Group] {
        if searchText.isEmpty {
            return groups
        }
        return groups.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }
    
    var body: some View {
        ZStack {
            themeManager.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Personal Groups")
                        .font(DesignSystem.Fonts.header())
                        .foregroundColor(themeManager.text)
                    Spacer()
                    
                    Button(action: { showCreateGroup = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
                .padding()
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search groups...", text: $searchText)
                        .foregroundColor(themeManager.text)
                }
                .padding()
                .background(themeManager.card)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom)
                
                if filteredGroups.isEmpty {
                    // Empty State
                    VStack {
                        Spacer()
                        
                        Image(systemName: "person.3.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No Personal Groups")
                            .font(DesignSystem.Fonts.header(20))
                            .foregroundColor(themeManager.text)
                            .padding(.top)
                        
                        Text("Create a group to chat with your friends")
                            .font(DesignSystem.Fonts.body())
                            .foregroundColor(themeManager.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: { showCreateGroup = true }) {
                            Text("Create Group")
                                .fontWeight(.bold)
                                .padding()
                                .padding(.horizontal, 20)
                                .background(DesignSystem.Colors.primary)
                                .foregroundColor(.white)
                                .cornerRadius(25)
                        }
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                } else {
                    // List
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredGroups) { group in
                                NavigationLink(destination: ChatView(viewModel: ChatViewModel(group: group, currentUser: authService.currentUser))) {
                                    HStack(spacing: 16) {
                                        // Group Logo
                                        if let logoUrl = group.logoUrl, !logoUrl.isEmpty {
                                            Image(logoUrl)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 50, height: 50)
                                                .clipShape(Circle())
                                                .overlay(
                                                    Circle()
                                                        .stroke(DesignSystem.Colors.primary.opacity(0.2), lineWidth: 1)
                                                )
                                        } else {
                                            // Fallback to text-based avatar
                                            ZStack {
                                                Circle()
                                                    .fill(DesignSystem.Colors.primary.opacity(0.1))
                                                    .frame(width: 50, height: 50)
                                                
                                                Text(String(group.name.prefix(1)))
                                                    .font(.title3)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(DesignSystem.Colors.primary)
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack {
                                                Text(group.name)
                                                    .font(DesignSystem.Fonts.body(16))
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(themeManager.text)
                                                Spacer()
                                                if let time = group.lastMessageTime {
                                                    Text(time.timeAgoDisplay())
                                                        .font(.caption2)
                                                        .foregroundColor(themeManager.textSecondary)
                                                }
                                            }
                                            
                                            Text(group.lastMessage ?? "No messages yet")
                                                .font(.subheadline)
                                                .foregroundColor(themeManager.textSecondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    .padding()
                                    .background(themeManager.background)
                                }
                                Divider().background(Color.gray.opacity(0.2))
                            }
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showCreateGroup) {
            StudentCreateGroupView()
        }
        .onAppear {
            startListening()
        }
        .onDisappear {
            stopListening()
        }
    }
    
    private func startListening() {
        stopListening()
        
        guard let userId = authService.currentUser?.userId else { return }
        
        listener = ChatService().fetchGroups(for: userId) { fetchedGroups in
            // Filter to personal groups only
            self.groups = fetchedGroups.filter { $0.isPersonal }
        }
    }
    
    private func stopListening() {
        listener?.remove()
        listener = nil
    }
}
