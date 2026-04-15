require 'xcodeproj'

project_path = 'HOOKFLOW.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'HOOKFLOW' }

# Step 1: Nuke ALL bad file references (the ones with paths at the root, or with no path)
bad_files = ['ScriptTemplate.swift', 'UserScriptModels.swift', 'ScriptDiscoveryModal.swift', 'MyScriptsView.swift', 'ScriptFolderDetailView.swift']

target.source_build_phase.files_references.each do |ref|
  if bad_files.include?(ref.name) || bad_files.include?(ref.path)
    puts "Deleting build file reference: #{ref.name || ref.path}"
    target.source_build_phase.remove_file_reference(ref)
  end
end

project.files.each do |ref|
  if bad_files.include?(ref.name) || bad_files.include?(ref.path)
    puts "Deleting file reference: #{ref.name || ref.path}"
    ref.remove_from_project
  end
end

project.save

project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'HOOKFLOW' }

files_to_add = [
  'Entities/ScriptTemplate.swift',
  'Entities/UserScriptModels.swift',
  'Features/Scripts/ScriptDiscoveryModal.swift',
  'Features/Scripts/MyScriptsView.swift',
  'Features/Scripts/ScriptFolderDetailView.swift'
]

files_to_add.each do |f|
  group_path = File.dirname(f)
  filename = File.basename(f)
  
  group = project.main_group
  group_path.split('/').each do |name|
    child = group.children.find { |c| c.class == Xcodeproj::Project::Object::PBXGroup && (c.name == name || c.path == name) }
    group = child || group.new_group(name, name)
  end
  
  file_ref = group.new_file(filename)
  target.add_file_references([file_ref])
  puts "Added #{f}"
end

project.save
