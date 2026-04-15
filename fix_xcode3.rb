require 'xcodeproj'

project_path = 'HOOKFLOW.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'HOOKFLOW' }

def remove_messed_up(group, target)
  to_delete = group.children.select { |c| c.class == Xcodeproj::Project::Object::PBXFileReference && c.path && c.path.end_with?('.swift') && c.path.include?('/') }
  to_delete.each do |ref|
    target.source_build_phase.files_references.delete(ref)
    ref.remove_from_project
  end
  group.children.select { |c| c.class == Xcodeproj::Project::Object::PBXGroup }.each do |g|
    remove_messed_up(g, target)
  end
end
remove_messed_up(project.main_group, target)

files_to_add = [
  'Entities/ScriptTemplate.swift',
  'Entities/UserScriptModels.swift',
  'Features/Scripts/ScriptDiscoveryModal.swift',
  'Features/Scripts/MyScriptsView.swift',
  'Features/Scripts/ScriptFolderDetailView.swift'
]

files_to_add.each do |file_path|
  path_components = file_path.split('/')
  filename = path_components.pop
  
  current_group = project.main_group
  path_components.each do |group_name|
    child_group = current_group.children.find { |c| c.class == Xcodeproj::Project::Object::PBXGroup && (c.name == group_name || c.path == group_name) }
    if child_group.nil?
      child_group = current_group.new_group(group_name, group_name)
    end
    current_group = child_group
  end
  
  file_ref = current_group.children.find { |c| c.class == Xcodeproj::Project::Object::PBXFileReference && c.path == filename }
  if file_ref.nil?
    file_ref = current_group.new_file(filename)
    target.add_file_references([file_ref])
    puts "Added #{file_path}"
  end
end

project.save
