require 'xcodeproj'

project_path = 'HOOKFLOW.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'HOOKFLOW' }

files_to_add = [
  'Entities/ScriptTemplate.swift',
  'Entities/UserScriptModels.swift',
  'Features/Scripts/ScriptDiscoveryModal.swift',
  'Features/Scripts/MyScriptsView.swift',
  'Features/Scripts/ScriptFolderDetailView.swift'
]

files_to_add.each do |file_path|
  # Split the path into directories
  path_components = file_path.split('/')
  filename = path_components.pop
  
  # Traverse / Create PBXGroup tree
  current_group = project.main_group
  path_components.each do |group_name|
    child_group = current_group.children.find { |c| c.class == Xcodeproj::Project::Object::PBXGroup && c.name == group_name || c.path == group_name }
    if child_group.nil?
      child_group = current_group.new_group(group_name)
    end
    current_group = child_group
  end
  
  # Check if file already in group
  if current_group.children.find { |c| c.path == filename }
    puts "#{file_path} already in project"
    next
  end

  # Add file reference
  file_ref = current_group.new_file(filename)
  
  # Add build file to target
  target.add_file_references([file_ref])
  puts "Added #{file_path} to project"
end

project.save
