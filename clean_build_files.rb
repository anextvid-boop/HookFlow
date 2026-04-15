require 'xcodeproj'

project_path = 'HOOKFLOW.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'HOOKFLOW' }

files_to_clean = ['ScriptTemplate.swift', 'UserScriptModels.swift', 'ScriptDiscoveryModal.swift', 'MyScriptsView.swift', 'ScriptFolderDetailView.swift']

# Keep track of one valid build_file per filename
seen = {}

target.source_build_phase.files.each do |build_file|
  ref = build_file.file_ref
  next unless ref
  name = ref.name || ref.path
  if files_to_clean.include?(name) || files_to_clean.include?(File.basename(name.to_s))
    basename = File.basename(name.to_s)
    if seen[basename]
      puts "Removing duplicate build file for #{basename}"
      target.source_build_phase.remove_build_file(build_file)
    else
      seen[basename] = true
    end
  end
end

project.save
