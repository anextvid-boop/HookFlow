require 'xcodeproj'

project_path = 'HOOKFLOW.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'HOOKFLOW' }

seen_paths = {}
duplicates = []

target.source_build_phase.files.each do |build_file|
  ref = build_file.file_ref
  next unless ref
  path = ref.path || ref.name
  if seen_paths[path]
    duplicates << build_file
  else
    seen_paths[path] = true
  end
end

duplicates.each do |dup|
  puts "Removing duplicate build file: #{dup.file_ref.path || dup.file_ref.name}"
  target.source_build_phase.remove_build_file(dup)
end

project.save
