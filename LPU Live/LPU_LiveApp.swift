import SwiftUI
import FirebaseCore

@main
struct LPU_LiveApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var themeManager = ThemeManager()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(themeManager)
                .environmentObject(themeManager)
        }
    }
}
