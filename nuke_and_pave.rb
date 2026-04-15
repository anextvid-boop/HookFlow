require 'xcodeproj'

project_path = 'HOOKFLOW.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'HOOKFLOW' }

files_to_clean = ['ScriptTemplate.swift', 'UserScriptModels.swift', 'ScriptDiscoveryModal.swift', 'MyScriptsView.swift', 'ScriptFolderDetailView.swift']

target.source_build_phase.files.each do |build_file|
  ref = build_file.file_ref
  if ref
    basename = File.basename((ref.path || ref.name).to_s)
    if files_to_clean.include?(basename)
      target.source_build_phase.remove_build_file(build_file)
    end
  end
end

project.files.each do |ref|
  basename = File.basename((ref.path || ref.name).to_s)
  if files_to_clean.include?(basename)
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
end
project.save
