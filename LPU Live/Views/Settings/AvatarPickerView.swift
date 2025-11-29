import SwiftUI

struct AvatarPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authService: AuthService
    
    let avatars = [
        "👨‍🎓", "👩‍🎓", "👨‍🏫", "👩‍🏫", "👨‍💻", "👩‍💻", "🦁", "🐯", "🐱", "🐶", "🦊", "🐻", "🐼", "🐨", "🧑‍🚀", "🦸‍♂️", "🦹‍♀️", "🧙‍♂️", "🧟‍♂️", "🧞‍♂️",
        "🦄", "🐲", "🦖", "🐙", "🦋", "🐝", "🐞", "🐠", "🐬", "🐳", "🦈", "🐊", "🐅", "🐆", "🦓", "🦍", "🦧", "🦣", "🐘", "🦛",
        "🦏", "🐪", "🐫", "🦒", "🦘", "🦬", "🐃", "🐂", "🐄", "🐎", "🐖", "🐏", "🐑", "🐐", "🦌", "🐕", "🐩", "🦮", "🐕‍🦺", "🐈",
        "🐈‍⬛", "🐓", "🦃", "🦚", "🦜", "🦢", "🦩", "🕊️", "🐇", "🦝", "🦨", "🦡", "🦫", "🦦", "🦥", "🐁", "🐀", "🐿️", "🦔", "🐾"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.background.ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 15) {
                        ForEach(avatars, id: \.self) { avatar in
                            Button(action: {
                                updateAvatar(avatar)
                            }) {
                                Text(avatar)
                                    .font(.system(size: 40))
                                    .frame(width: 60, height: 60)
                                    .background(themeManager.card)
                                    .cornerRadius(30)
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Choose Avatar")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    func updateAvatar(_ avatar: String) {
        guard let userId = authService.currentUser?.userId else { return }
        
        Task {
            do {
                try await UserService().updateUserAvatar(userId: userId, avatar: avatar)
                await MainActor.run {
                    // Update local user state immediately for UI feedback
                    if var currentUser = authService.currentUser {
                        currentUser.profileImageUrl = avatar
                        authService.currentUser = currentUser
                    }
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                print("Error updating avatar: \(error.localizedDescription)")
            }
        }
    }
}
