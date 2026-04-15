require 'xcodeproj'
require 'find'

project_path = 'HOOKFLOW.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'HOOKFLOW' }

# Nuke all swift files from source build phase
target.source_build_phase.files_references.each do |ref|
  target.source_build_phase.remove_file_reference(ref)
end

# Nuke all swift file references from project completely
project.files.each do |ref|
  if ref.path && ref.path.end_with?('.swift')
    ref.remove_from_project
  end
end

project.save

# Now build the project tree from the actual filesystem!
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'HOOKFLOW' }

Dir.glob('**/*.swift').each do |swift_file|
  next if swift_file.start_with?('Pods/') || swift_file.start_with?('build/')
  
  group_path = File.dirname(swift_file)
  filename = File.basename(swift_file)
  
  # Ensure groups have correct paths
  current_group = project.main_group
  if group_path != '.'
    group_path.split('/').each do |group_name|
      child = current_group.children.find { |c| c.class == Xcodeproj::Project::Object::PBXGroup && (c.name == group_name || c.path == group_name) }
      if child.nil?
        child = current_group.new_group(group_name, group_name)
      end
      current_group = child
    end
  end
  
  file_ref = current_group.new_file(filename)
  target.add_file_references([file_ref])
end
project.save
