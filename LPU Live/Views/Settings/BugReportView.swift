import SwiftUI

struct BugReportView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var id = ""
    @State private var category = "UI/UX"
    @State private var department = ""
    @State private var description = ""
    
    let categories = ["UI/UX", "Performance", "Crash", "Feature Request", "Other"]
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.background.ignoresSafeArea()
                
                Form {
                    Section(header: Text("User Info")) {
                        TextField("Name", text: $name)
                        TextField("ID", text: $id)
                        TextField("Department", text: $department)
                    }
                    
                    Section(header: Text("Bug Details")) {
                        Picker("Category", selection: $category) {
                            ForEach(categories, id: \.self) {
                                Text($0)
                            }
                        }
                        
                        TextEditor(text: $description)
                            .frame(height: 100)
                    }
                    
                    Section {
                        Button("Submit Report") {
                            // Submit logic here
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
            }
            .navigationTitle("Report a Bug")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
