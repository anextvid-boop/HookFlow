require 'xcodeproj'

project_path = 'HOOKFLOW.xcodeproj'
project = Xcodeproj::Project.open(project_path)

files_to_fix = [
  { group_path: 'Entities', ref_path: 'ScriptTemplate.swift', actual_path: 'Entities/ScriptTemplate.swift' },
  { group_path: 'Entities', ref_path: 'UserScriptModels.swift', actual_path: 'Entities/UserScriptModels.swift' },
  { group_path: 'Features/Scripts', ref_path: 'ScriptDiscoveryModal.swift', actual_path: 'Features/Scripts/ScriptDiscoveryModal.swift' },
  { group_path: 'Features/Scripts', ref_path: 'MyScriptsView.swift', actual_path: 'Features/Scripts/MyScriptsView.swift' },
  { group_path: 'Features/Scripts', ref_path: 'ScriptFolderDetailView.swift', actual_path: 'Features/Scripts/ScriptFolderDetailView.swift' }
]

def find_group(project, path)
  group = project.main_group
  path.split('/').each do |name|
    group = group.children.find { |c| c.class == Xcodeproj::Project::Object::PBXGroup && (c.name == name || c.path == name) }
  end
  group
end

files_to_fix.each do |f|
  group = find_group(project, f[:group_path])
  if group
    file_ref = group.children.find { |c| c.class == Xcodeproj::Project::Object::PBXFileReference && c.path == f[:ref_path] }
    if file_ref
      # Actually we want the path to be relative to the group, so maybe just the filename if the group has the correct path.
      # Let's just set the path of the group properly if it isn't set, or set the file_ref's relative path.
      # The safest way is to set its path and sourceTree explicitly.
      file_ref.set_path(f[:actual_path])
      file_ref.source_tree = '<group>'
      puts "Fixed path for #{f[:actual_path]}"
    end
  end
end

project.save
