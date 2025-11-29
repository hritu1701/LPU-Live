import SwiftUI

struct ChatView: View {
    @StateObject var viewModel: ChatViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showGroupMembers = false
    @State private var showDeleteAlert = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            themeManager.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (Custom if needed, but NavigationBar handles it)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.messages.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Spacer()
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundColor(themeManager.textSecondary.opacity(0.5))
                        
                        Text("No messages yet")
                            .font(DesignSystem.Fonts.header(20))
                            .foregroundColor(themeManager.textSecondary)
                        
                        Text("Be the first to start the conversation!")
                            .font(DesignSystem.Fonts.body())
                            .foregroundColor(themeManager.textSecondary)
                        
                        Spacer()
                    }
                } else {
                    // Message List
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(message: message, isCurrentUser: message.senderId == viewModel.currentUser?.userId)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: viewModel.messages.count) {
                            if let lastId = viewModel.messages.last?.id {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input Area (Only if allowed)
                if viewModel.canSendMessage {
                    HStack(spacing: 12) {
                        Button(action: {}) {
                            Image(systemName: "plus")
                                .foregroundColor(themeManager.textSecondary)
                        }
                        
                        TextField("Type a message...", text: $viewModel.newMessageText)
                            .padding(10)
                            .background(themeManager.background)
                            .cornerRadius(20)
                            .foregroundColor(themeManager.text)
                        
                        Button(action: {
                            Task {
                                await viewModel.sendMessage()
                            }
                        }) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                        .disabled(viewModel.newMessageText.isEmpty)
                    }
                    .padding()
                    .background(themeManager.card)
                } else {
                    // Read Only Message
                    Text("Only teachers can send messages in this group")
                        .font(.caption)
                        .foregroundColor(themeManager.textSecondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(themeManager.card)
                }
            }
        }
        .navigationTitle(viewModel.group.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Group Info Button
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showGroupMembers = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(themeManager.text)
                }
            }
            
            // Admin Menu
            if viewModel.currentUser?.role == .admin {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive, action: {
                            Task {
                                await viewModel.clearChat()
                            }
                        }) {
                            Label("Clear Chat", systemImage: "trash")
                        }
                        
                        Button(role: .destructive, action: {
                            showDeleteAlert = true
                        }) {
                            Label("Delete Group", systemImage: "trash.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(themeManager.text)
                    }
                }
            }
        }
        .sheet(isPresented: $showGroupMembers) {
            GroupMembersView(group: viewModel.group)
        }
        .alert("Delete Group", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteGroup()
            }
        } message: {
            Text("Are you sure you want to delete '\(viewModel.group.name)'? This will delete all messages and cannot be undone.")
        }
    }
    
    private func deleteGroup() {
        guard let groupId = viewModel.group.id else { return }
        
        Task {
            do {
                try await ChatService().deleteGroup(groupId: groupId)
                print("✅ Group deleted successfully")
                // Navigate back after deletion
                await MainActor.run {
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                print("❌ Error deleting group: \(error.localizedDescription)")
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    let isCurrentUser: Bool
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isCurrentUser {
                // Avatar - Use LPU logo for admin
                if message.senderName == "Admin" {
                    Image("lpu_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay(Text(message.senderName.prefix(1)).font(.caption))
                }
            } else {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(message.senderName)
                        .font(.caption2)
                        .foregroundColor(themeManager.textSecondary)
                }
                
                Text(message.content)
                    .padding(12)
                    .background(isCurrentUser ? DesignSystem.Colors.primary : themeManager.card)
                    .foregroundColor(isCurrentUser ? .white : themeManager.text)
                    .cornerRadius(16)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                Text(message.timestamp.chatTime())
                    .font(.caption2)
                    .foregroundColor(themeManager.textSecondary)
            }
            
            if !isCurrentUser {
                Spacer()
            }
        }
    }
}
