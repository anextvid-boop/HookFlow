require 'xcodeproj'
project_path = 'HOOKFLOW.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

file_path = 'DesignSystem/HFAmbientAura.swift'
group = project.main_group.find_subpath(File.dirname(file_path), true)

existing_file = group.files.find { |f| f.path == File.basename(file_path) }

if existing_file.nil?
    group.set_source_tree('SOURCE_ROOT')
    file_ref = group.new_file(File.basename(file_path))
    target.add_file_references([file_ref])
    project.save
    puts "Added HFAmbientAura.swift to project"
else
    puts "HFAmbientAura.swift already in project"
end
