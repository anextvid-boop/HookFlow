import SwiftUI
import SwiftData

struct ScriptFolderDetailView: View {
    let group: UserScriptGroup
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingMoveModal = false
    @State private var scriptToMove: UserScript?
    
    // Sort scripts securely taking `orderIndex` bounds into consideration.
    var sortedScripts: [UserScript] {
        group.scripts.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if group.scripts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 64))
                        .foregroundColor(.gray)
                    Text("Folder is Empty")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Add custom scripts or duplicate templates here.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            } else {
                List {
                    ForEach(sortedScripts) { script in
                        NavigationLink(destination: Text("Open Editor Placeholder Phase 8")) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(script.title)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Last edited: \(script.lastEdited.formatted(.dateTime.month().day().hour().minute()))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                        }
                        // Phase 7, Step 4.2 & 4.3: Link contextMenu "Move to Folder" and "Duplicate"
                        .contextMenu {
                            Button {
                                duplicateScript(script)
                            } label: {
                                Label("Duplicate Script", systemImage: "plus.square.on.square")
                            }
                            
                            Button {
                                scriptToMove = script
                                showingMoveModal = true
                            } label: {
                                Label("Move to Folder", systemImage: "folder")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                deleteScript(script)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    // Phase 7, Step 4.1: Explicit `.onMove(perform:)` callbacks mechanically mutating the `scripts` array mapping the order
                    .onMove(perform: moveScripts)
                }
                .listStyle(PlainListStyle())
                .background(Color.black)
            }
        }
        .navigationTitle(group.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
        // Phase 7, Step 4.2: rendering a modal specifically returning absolute SwiftData Group selections safely mapping data blocks natively
        .sheet(item: $scriptToMove) { script in
            MoveToFolderModal(script: script, currentFolder: group)
        }
    }
    
    private func deleteScript(_ script: UserScript) {
        group.scripts.removeAll(where: { $0.id == script.id })
        modelContext.delete(script)
        try? modelContext.save()
    }
    
    // Phase 7, Step 4.3: "Duplicate Script" context functions automating exact record cloning
    private func duplicateScript(_ script: UserScript) {
        let clone = UserScript(
            title: "\(script.title) (Copy)",
            content: script.content,
            orderIndex: group.scripts.count,
            isEditable: true
        )
        group.scripts.append(clone)
        modelContext.insert(clone)
        try? modelContext.save()
    }
    
    // Phase 7, Step 4.1 & 4.4: Safely mapping order explicitly inside SwiftData records uniquely sorting by `orderIndex`
    private func moveScripts(from source: IndexSet, to destination: Int) {
        var mutableScripts = sortedScripts
        mutableScripts.move(fromOffsets: source, toOffset: destination)
        
        for (index, script) in mutableScripts.enumerated() {
            script.orderIndex = index
        }
        
        // Phase 7, Step 4.4: Hook explicit `SwiftData` context `.save()` triggers directly at the physical tail end
        try? modelContext.save()
    }
}

// Modal for "Move to Folder" natively executing relationship changes globally
struct MoveToFolderModal: View {
    let script: UserScript
    let currentFolder: UserScriptGroup
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserScriptGroup.creationDate, order: .reverse) private var allGroups: [UserScriptGroup]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(allGroups) { group in
                    Button {
                        move(to: group)
                    } label: {
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                            Text(group.name)
                                .foregroundColor(.white)
                            Spacer()
                            if group.id == currentFolder.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .disabled(group.id == currentFolder.id)
                }
            }
            .navigationTitle("Move to Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func move(to targetGroup: UserScriptGroup) {
        // Disconnect from old
        currentFolder.scripts.removeAll(where: { $0.id == script.id })
        
        // Connect to new
        script.orderIndex = targetGroup.scripts.count
        targetGroup.scripts.append(script)
        
        try? modelContext.save()
        dismiss()
    }
}
