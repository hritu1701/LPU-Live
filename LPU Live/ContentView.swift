import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
            } else {
                SwiftUI.Group {
                    if authService.isAuthenticated {
                        MainTabView()
                    } else {
                        SignInView()
                    }
                }
                .accentColor(DesignSystem.Colors.primary)
                .transition(.opacity)
            }
        }
        .onAppear {
            // Hide splash screen after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}
