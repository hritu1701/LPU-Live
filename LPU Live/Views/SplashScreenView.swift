import SwiftUI

struct SplashScreenView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isAnimating = false
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.5
    
    var body: some View {
        ZStack {
            // Dynamic background based on theme
            themeManager.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // LPU Logo
                Image("lpu_logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 220, height: 220)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                // App Name
                Text("LPU LIVE")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(DesignSystem.Colors.primary)
                    .opacity(opacity)
                
                // Tagline
                Text("Connect • Learn • Grow")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeManager.textSecondary)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Pulse animation
            withAnimation(
                .easeInOut(duration: 1.0)
                .repeatCount(2, autoreverses: true)
                .delay(0.8)
            ) {
                scale = 1.05
            }
        }
    }
}
