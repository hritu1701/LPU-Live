import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authService: AuthService
    @State private var showBugReport = false
    @State private var showAvatarPicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.background.ignoresSafeArea()
                
                ScrollView {
                     VStack(spacing: 20) {
                        // Profile Section
                        VStack(spacing: 12) {
                            // Avatar - Use LPU logo for admin
                            if authService.currentUser?.role == .admin {
                                Image("lpu_logo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                            } else if let avatar = authService.currentUser?.profileImageUrl, !avatar.isEmpty {
                                Text(avatar)
                                    .font(.system(size: 60))
                                    .frame(width: 80, height: 80)
                                    .background(themeManager.card)
                                    .clipShape(Circle())
                                    .shadow(radius: 2)
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(spacing: 4) {
                                Text(authService.currentUser?.role == .admin ? "Admin" : (authService.currentUser?.name ?? "User"))
                                    .font(DesignSystem.Fonts.header(20))
                                    .foregroundColor(themeManager.text)
                                
                                Text(authService.currentUser?.role == .admin ? "•••••" : (authService.currentUser?.userId ?? "ID"))
                                    .font(DesignSystem.Fonts.body())
                                    .foregroundColor(themeManager.textSecondary)
                                
                                Text(authService.currentUser?.role.title ?? "Role")
                                    .font(DesignSystem.Fonts.caption())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(DesignSystem.Colors.primary.opacity(0.2))
                                    .foregroundColor(DesignSystem.Colors.primary)
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(themeManager.card)
                        .cornerRadius(12)
                        
                        // Settings Menu
                        VStack(spacing: 0) {
                            // Only show avatar picker for non-admin users
                            if authService.currentUser?.role != .admin {
                                Button(action: { showAvatarPicker = true }) {
                                    SettingsRow(icon: "face.smiling", title: "Apply Custom Avatar")
                                }
                                Divider().background(Color.gray.opacity(0.2))
                            }
                            SettingsRow(icon: "lock.shield", title: "Privacy Protect")
                            Divider().background(Color.gray.opacity(0.2))
                            SettingsRow(icon: "bell", title: "Allow Notifications")
                        }
                        .background(themeManager.card)
                        .cornerRadius(12)
                        
                        // Support
                        VStack(spacing: 0) {
                            Button(action: { showBugReport = true }) {
                                SettingsRow(icon: "ladybug", title: "Report a Bug")
                            }
                            Divider().background(Color.gray.opacity(0.2))
                            Link(destination: URL(string: "https://ums.lpu.in/lpuums/")!) {
                                SettingsRow(icon: "globe", title: "Visit UMS Portal")
                            }
                        }
                        .background(themeManager.card)
                        .cornerRadius(12)
                        
                        // Logout
                        Button(action: {
                            authService.signOut()
                        }) {
                            Text("Logout")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(12)
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showBugReport) {
                BugReportView()
            }
            .sheet(isPresented: $showAvatarPicker) {
                AvatarPickerView()
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundColor(themeManager.textSecondary)
            Text(title)
                .foregroundColor(themeManager.text)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
    }
}
