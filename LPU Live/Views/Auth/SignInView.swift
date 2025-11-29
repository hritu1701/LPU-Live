import SwiftUI

struct SignInView: View {
    @StateObject private var viewModel = AuthViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            // Background
            themeManager.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // LPU Logo
                        Image("lpu_logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150, height: 150)
                            .padding(.top, 40)
                        
                        Text("LPU LIVE")
                            .font(DesignSystem.Fonts.body(14))
                            .foregroundColor(themeManager.textSecondary)
                        
                        Text("Sign in to continue")
                            .font(DesignSystem.Fonts.body())
                            .foregroundColor(themeManager.textSecondary)
                            .padding(.top, 8)
                        
                        // Form
                        VStack(spacing: 20) {
                            // Registration Number Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Registration Number")
                                    .font(DesignSystem.Fonts.caption())
                                    .foregroundColor(themeManager.textSecondary)
                                
                                TextField("Enter your Registration Number", text: $viewModel.userId)
                                    .padding()
                                    .background(themeManager.card)
                                    .cornerRadius(12)
                                    .foregroundColor(themeManager.text)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .keyboardType(.numberPad)
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(DesignSystem.Fonts.caption())
                                    .foregroundColor(themeManager.textSecondary)
                                
                                HStack {
                                    if viewModel.isPasswordVisible {
                                        TextField("Enter your password", text: $viewModel.password)
                                    } else {
                                        SecureField("Enter your password", text: $viewModel.password)
                                    }
                                    
                                    Button(action: { viewModel.isPasswordVisible.toggle() }) {
                                        Image(systemName: viewModel.isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(themeManager.card)
                                .cornerRadius(12)
                                .foregroundColor(themeManager.text)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            // Forgot Password
                            HStack {
                                Spacer()
                                Button("Forgot password?") {
                                    // Action
                                }
                                .font(DesignSystem.Fonts.caption())
                                .foregroundColor(DesignSystem.Colors.primary)
                            }
                            
                            // Sign In Button
                            Button(action: {
                                Task {
                                    await viewModel.signIn()
                                }
                            }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Sign In")
                                            .fontWeight(.bold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(DesignSystem.Colors.primary)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(viewModel.isLoading || !viewModel.isValid)
                            .opacity(viewModel.isValid ? 1.0 : 0.6)
                            
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
                
                // Footer
                VStack(spacing: 16) {
                    // UMS Link
                    Link("Visit UMS Portal", destination: URL(string: "https://ums.lpu.in/lpuums/")!)
                        .font(.caption)
                        .foregroundColor(DesignSystem.Colors.primary)
                        .padding(.top, 4)
                }
                .padding(.bottom, 20)
            }
        }
    }
}
