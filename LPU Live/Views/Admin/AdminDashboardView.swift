import SwiftUI

struct AdminDashboardView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var adminService = AdminService()
    @State private var showCreateGroup = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Quick Actions
                        VStack(alignment: .leading) {
                            Text("Quick Actions")
                                .font(DesignSystem.Fonts.header(18))
                                .foregroundColor(themeManager.text)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    AdminActionCard(icon: "plus.circle.fill", title: "Create Group", color: .orange) {
                                        showCreateGroup = true
                                    }
                                    
                                    AdminActionCard(icon: "person.badge.plus.fill", title: "Add User", color: .blue) {
                                        // Add User Action
                                    }
                                    
                                    AdminActionCard(icon: "megaphone.fill", title: "Broadcast", color: .green) {
                                        // Broadcast Action
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Recent Activity / Stats
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Overview")
                                    .font(DesignSystem.Fonts.header(18))
                                    .foregroundColor(themeManager.text)
                                Spacer()
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .foregroundColor(DesignSystem.Colors.primary)
                                    .font(.caption)
                            }
                            .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                StatRow(title: "Total Users", value: "\(adminService.totalUsers)", icon: "person.2.fill")
                                StatRow(title: "Active Groups", value: "\(adminService.activeGroups)", icon: "bubble.left.and.bubble.right.fill")
                                StatRow(title: "Messages Today", value: "\(adminService.messagesToday)", icon: "message.fill")
                            }
                            .padding()
                            .background(themeManager.card)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Admin Dashboard")
            .sheet(isPresented: $showCreateGroup) {
                CreateGroupView()
            }
            .onAppear {
                adminService.startListening()
            }
            .onDisappear {
                adminService.stopListening()
            }
        }
    }
}

struct AdminActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(color)
                
                Text(title)
                    .font(DesignSystem.Fonts.caption())
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.text)
            }
            .frame(width: 120, height: 120)
            .background(themeManager.card)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 30)
                .foregroundColor(DesignSystem.Colors.primary)
            
            Text(title)
                .foregroundColor(themeManager.textSecondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.bold)
                .foregroundColor(themeManager.text)
        }
        .padding(.vertical, 4)
    }
}
