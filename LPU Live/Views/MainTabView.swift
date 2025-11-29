import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                GroupListView()
            }
            .tabItem {
                Label("LPU LIVE", systemImage: "building.columns.fill")
            }
            .tag(0)
            
            NavigationView {
                PersonalGroupListView()
            }
            .tabItem {
                Label("Personal", systemImage: "person.3.fill")
            }
            .tag(1)
            
            NavigationView {
                PersonalChatListView()
            }
            .tabItem {
                Label("Chats", systemImage: "message.fill")
            }
            .tag(2)
            
            Text("Notifications")
                .tabItem {
                    Label("Notifications", systemImage: "bell.fill")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
            
            if authService.currentUser?.role == .admin {
                AdminDashboardView()
                    .tabItem {
                        Label("Admin", systemImage: "shield.fill")
                    }
                    .tag(5)
            }
        }
        .accentColor(DesignSystem.Colors.primary)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(themeManager.card)
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
