import SwiftUI
import SwiftData

struct MyScriptsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserScriptGroup.creationDate, order: .reverse) private var groups: [UserScriptGroup]
    
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    
    @State private var scriptToDelete: UserScriptGroup?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.black.ignoresSafeArea()
                
                if groups.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        Text("No Script Folders")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Create a folder to start organizing your custom scripts and templates.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(groups) { group in
                            // Phase 7, Step 2.4: Custom list structures routing directly to a NavigationLink
                            NavigationLink(destination: ScriptFolderDetailView(group: group)) {
                                HStack(spacing: 16) {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.blue)
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(group.name)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text("\(group.scripts.count) scripts")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            // Phase 7, Step 2.3: Explicit Swipe actions exposing destructive Delete
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    scriptToDelete = group
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.black)
                }
            }
            .navigationTitle("My Scripts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        newFolderName = ""
                        showingNewFolderAlert = true
                    }) {
                        Image(systemName: "folder.badge.plus")
                            .foregroundColor(.blue)
                    }
                }
            }
            // Phase 7, Step 2.1 & 2.2: "New Folder" alert-based UX capturing immediate TextField injections
            .alert("New Folder", isPresented: $showingNewFolderAlert) {
                TextField("Folder Name", text: $newFolderName)
                
                Button("Cancel", role: .cancel) { }
                Button("Create") {
                    let trimmed = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return } // Prevention limit
                    
                    let newGroup = UserScriptGroup(name: trimmed)
                    modelContext.insert(newGroup)
                    try? modelContext.save()
                }
                .disabled(newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) // Active empty-string bounds
            } message: {
                Text("Enter a name for your new script folder.")
            }
            .alert("Delete Folder?", isPresented: $showingDeleteConfirmation, presenting: scriptToDelete) { group in
                Button("Cancel", role: .cancel) {
                    scriptToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    // Wipes the memory schema naturally traversing .cascade relationship bounds mechanically
                    modelContext.delete(group)
                    try? modelContext.save()
                    scriptToDelete = nil
                }
            } message: { group in
                Text("Are you sure you want to delete '\(group.name)'? This will physically destroy all \(group.scripts.count) scripts inside it. This action cannot be undone.")
            }
        }
    }
}
