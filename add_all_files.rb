require 'xcodeproj'
require 'find'

project_path = 'HOOKFLOW.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'HOOKFLOW' }

existing_files = target.source_build_phase.files_references.map { |r| r.path || r.name }.compact

files_to_add = []
Find.find('.') do |path|
  next if path =~ /^\.\/(Pods|build|DerivedData|\.git|HOOKFLOW\.xcodeproj|hookflow_plans)/
  if path.end_with?('.swift')
    filename = File.basename(path)
    unless existing_files.include?(filename)
      files_to_add << path.sub('./', '')
    end
  end
end

puts "Found potentially missing files: #{files_to_add}"

files_to_add.each do |f|
  group_path = File.dirname(f)
  filename = File.basename(f)
  
  group = project.main_group
  group_path.split('/').each do |name|
    child = group.children.find { |c| c.class == Xcodeproj::Project::Object::PBXGroup && (c.name == name || c.path == name) }
    group = child || group.new_group(name, name)
  end
  
  file_ref = group.children.find { |c| c.class == Xcodeproj::Project::Object::PBXFileReference && c.path == filename }
  if file_ref.nil?
    file_ref = group.new_file(filename)
    target.add_file_references([file_ref])
    puts "Added #{f}"
  end
end

project.save
