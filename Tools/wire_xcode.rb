#!/usr/bin/env ruby
# wire_xcode.rb — adds Shared/, iOS/, tvOS/, Watch/ as Xcode 16 synchronized
# folder groups to the right targets, and bumps the Watch deployment target.
#
# Idempotent — re-running won't create duplicates.

require "xcodeproj"

PROJ_PATH = "Reflect.xcodeproj"
proj = Xcodeproj::Project.open(PROJ_PATH)

# --- Helpers ---------------------------------------------------------------

def find_or_create_sync_group(proj, path)
  existing = proj.objects.find do |o|
    o.isa == "PBXFileSystemSynchronizedRootGroup" && o.path == path
  end
  return existing if existing

  g = proj.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
  g.source_tree = "<group>"
  g.path = path
  proj.main_group << g
  puts "  created sync group: #{path}"
  g
end

def link_group_to_target(target, group)
  existing = target.file_system_synchronized_groups
  unless existing.any? { |g| g.uuid == group.uuid }
    existing << group
    puts "  #{target.name} <- #{group.path}"
  end
end

# --- 1. Create sync groups -------------------------------------------------

puts "Creating synchronized folder groups..."
shared_group = find_or_create_sync_group(proj, "Shared")
ios_group    = find_or_create_sync_group(proj, "iOS")
tvos_group   = find_or_create_sync_group(proj, "tvOS")
watch_group  = find_or_create_sync_group(proj, "Watch")

# --- 2. Link to targets ----------------------------------------------------

puts "Linking groups to targets..."
reflect_target    = proj.targets.find { |t| t.name == "Reflect" }
tv_target         = proj.targets.find { |t| t.name == "Reflect TV" }
watch_target      = proj.targets.find { |t| t.name == "Reflect Watch Watch App" }

# Shared/ -> all three app targets
[reflect_target, tv_target, watch_target].each { |t| link_group_to_target(t, shared_group) }

# Per-platform groups
link_group_to_target(reflect_target, ios_group)
link_group_to_target(tv_target,      tvos_group)
link_group_to_target(watch_target,   watch_group)

# --- 3. Remove obsolete shared-file exceptions -----------------------------
#
# Pre-existing project used PBXFileSystemSynchronizedBuildFileExceptionSet
# entries to share Reflect/Prompts.swift into the TV + Watch targets.
# Now that Prompts.swift has moved to Shared/ (which is a sync group on
# all three targets), those exceptions cause duplicate compilation.

puts "Removing obsolete shared-file exceptions..."
obsolete = proj.objects.select do |o|
  o.isa == "PBXFileSystemSynchronizedBuildFileExceptionSet" &&
    Array(o.respond_to?(:membership_exceptions) ? o.membership_exceptions : nil).include?("Prompts.swift")
end
obsolete.each do |o|
  puts "  removed exception set #{o.uuid}"
  o.remove_from_project
end

# --- 4. Bump Watch deployment target to 11.0 -------------------------------

puts "Bumping Watch deployment target..."
watch_target.build_configurations.each do |bc|
  current = bc.build_settings["WATCHOS_DEPLOYMENT_TARGET"]
  if current != "11.0"
    bc.build_settings["WATCHOS_DEPLOYMENT_TARGET"] = "11.0"
    puts "  #{bc.name}: WATCHOS_DEPLOYMENT_TARGET #{current} -> 11.0"
  end
end

# --- 4. Save ---------------------------------------------------------------

proj.save
puts "Saved #{PROJ_PATH}"
