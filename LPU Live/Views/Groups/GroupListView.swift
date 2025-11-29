import SwiftUI
import FirebaseFirestore

struct GroupListView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authService: AuthService
    @State private var searchText = ""
    @State private var groups: [Group] = []
    @State private var showCreateGroup = false
    
    @State private var listener: ListenerRegistration?
    
    var filteredGroups: [Group] {
        if searchText.isEmpty {
            return groups.filter { !$0.isPersonal }
        }
        return groups.filter { group in
            !group.isPersonal &&
            group.name.lowercased().contains(searchText.lowercased())
        }
    }
    
    var body: some View {
        ZStack {
            themeManager.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
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
        .navigationTitle("Groups")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if authService.currentUser?.role == .admin {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateGroup = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateGroup) {
            CreateGroupView()
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
        listener = ChatService().fetchGroups(for: authService.currentUser?.userId) { fetchedGroups in
            self.groups = fetchedGroups
        }
    }
    
    private func stopListening() {
        listener?.remove()
        listener = nil
    }
}
