#!/usr/bin/env ruby
# Register a Swift source file into a group + target of Tersten.xcodeproj.
#
# Usage: ruby scripts/add_engine_file.rb <relative_path> <group_name> <target_name>
#   e.g. ruby scripts/add_engine_file.rb Tersten/Engine/Puzzle.swift Engine Engine
#
# Idempotent: skips a file already present in the target's sources.

require "xcodeproj"

rel_path, group_name, target_name = ARGV
abort "usage: add_engine_file.rb <path> <group> <target>" unless rel_path && group_name && target_name

project_path = File.join(File.dirname(__FILE__), "..", "Tersten", "Tersten.xcodeproj")
project = Xcodeproj::Project.open(project_path)

group = project.main_group.children.find { |c| c.isa == "PBXGroup" && c.display_name == group_name }
abort "group not found: #{group_name}" unless group

target = project.targets.find { |t| t.name == target_name }
abort "target not found: #{target_name}" unless target

basename = File.basename(rel_path)

if target.source_build_phase.files.any? { |f| f.file_ref&.display_name == basename }
  puts "already present in #{target_name}: #{basename}"
  exit 0
end

# The file path stored in the group is relative to the group's own folder; the
# groups here mirror the on-disk folders (Engine/, EngineTests/), so the
# basename is the correct group-relative path.
file_ref = group.new_reference(basename)
target.add_file_references([file_ref])
project.save

puts "added #{basename} to group #{group_name} + target #{target_name}"
