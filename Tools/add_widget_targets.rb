#!/usr/bin/env ruby
# add_widget_targets.rb — add ReflectWidget (iOS/iPadOS/Mac) and
# ReflectWatchWidget (watchOS complication) extension targets to the
# Xcode project. Both use Xcode 16 synchronized folder groups so file
# membership is automatic.
#
# Idempotent — re-running is safe.

require "xcodeproj"

PROJ_PATH = "Reflect.xcodeproj"
TEAM_ID   = "FBUNBDS7R7"
proj = Xcodeproj::Project.open(PROJ_PATH)

# --- Helpers ---------------------------------------------------------------

def find_target(proj, name)
  proj.targets.find { |t| t.name == name }
end

def find_or_create_sync_group(proj, path)
  existing = proj.objects.find do |o|
    o.isa == "PBXFileSystemSynchronizedRootGroup" && o.path == path
  end
  return existing if existing
  g = proj.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
  g.source_tree = "<group>"
  g.path = path
  proj.main_group << g
  g
end

def link_sync_group(target, group)
  list = target.file_system_synchronized_groups
  unless list.any? { |g| g.uuid == group.uuid }
    list << group
  end
end

# Exclude specific files in a sync group from a target's build (e.g. Info.plist
# which is consumed via INFOPLIST_FILE, not as a bundle resource).
def exclude_files_from_target(proj, group, target, filenames)
  return if filenames.empty?
  existing = proj.objects.find do |o|
    o.isa == "PBXFileSystemSynchronizedBuildFileExceptionSet" &&
      o.respond_to?(:target) && o.target&.uuid == target.uuid &&
      o.respond_to?(:membership_exceptions) &&
      (Array(o.membership_exceptions) - filenames).empty? &&
      (filenames - Array(o.membership_exceptions)).empty?
  end
  return if existing

  exc = proj.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedBuildFileExceptionSet)
  exc.target = target
  exc.membership_exceptions = filenames
  (group.exceptions ||= []) << exc
end

# --- 1. Find host targets --------------------------------------------------

ios_app   = find_target(proj, "Reflect")               or abort "Reflect target missing"
watch_app = find_target(proj, "Reflect Watch Watch App") or abort "Watch target missing"

# Carry over deployment targets and signing settings from hosts.
ios_deploy   = ios_app.build_configurations.first.build_settings["IPHONEOS_DEPLOYMENT_TARGET"]   || "18.0"
watch_deploy = watch_app.build_configurations.first.build_settings["WATCHOS_DEPLOYMENT_TARGET"] || "11.0"
swift_ver    = ios_app.build_configurations.first.build_settings["SWIFT_VERSION"] || "5.0"

# Sync groups created by the previous wire_xcode.rb run
shared_group = proj.objects.find { |o| o.isa == "PBXFileSystemSynchronizedRootGroup" && o.path == "Shared" }
abort "Shared sync group missing — run wire_xcode.rb first" if shared_group.nil?

# --- 2. iOS Widget extension target ---------------------------------------

WIDGET_NAME    = "ReflectWidget"
WIDGET_BUNDLE  = "com.MarkFriedlander.Reflect.widget"

widget_target = find_target(proj, WIDGET_NAME)
if widget_target.nil?
  puts "Creating target: #{WIDGET_NAME}"
  widget_target = proj.new_target(
    :app_extension,
    WIDGET_NAME,
    :ios,
    ios_deploy,
    proj.products_group,
    :swift
  )
else
  puts "Target #{WIDGET_NAME} exists — updating settings"
end

# Sync group for Widget/
widget_group = find_or_create_sync_group(proj, "Widget")
link_sync_group(widget_target, widget_group)
link_sync_group(widget_target, shared_group)
# Info.plist is the target's INFOPLIST_FILE, so it must NOT also be
# included as a bundle resource.
exclude_files_from_target(proj, widget_group, widget_target, ["Info.plist"])

# Build settings
widget_target.build_configurations.each do |bc|
  bs = bc.build_settings
  bs["PRODUCT_BUNDLE_IDENTIFIER"]      = WIDGET_BUNDLE
  bs["PRODUCT_NAME"]                   = "$(TARGET_NAME)"
  bs["INFOPLIST_FILE"]                 = "Widget/Info.plist"
  bs["IPHONEOS_DEPLOYMENT_TARGET"]     = ios_deploy
  bs["SWIFT_VERSION"]                  = swift_ver
  bs["TARGETED_DEVICE_FAMILY"]         = "1,2"
  bs["SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD"] = "YES"
  bs["SUPPORTS_MACCATALYST"]           = "NO"
  bs["GENERATE_INFOPLIST_FILE"]        = "NO"
  bs["DEVELOPMENT_TEAM"]               = TEAM_ID
  bs["CODE_SIGN_STYLE"]                = "Automatic"
  bs["SKIP_INSTALL"]                   = "YES"
  bs["LD_RUNPATH_SEARCH_PATHS"]        = "$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks"
  bs["MARKETING_VERSION"]              = "1.0"
  bs["CURRENT_PROJECT_VERSION"]        = "1"
  # iOS 26 minimum for WidgetKit App Intent button support inherited from host
  bs["ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS"] = "NO"
end

# Embed in iOS app
embed_phase = ios_app.copy_files_build_phases.find { |p| p.name == "Embed App Extensions" }
if embed_phase.nil?
  embed_phase = ios_app.new_copy_files_build_phase("Embed App Extensions")
  embed_phase.symbol_dst_subfolder_spec = :plug_ins
  embed_phase.run_only_for_deployment_postprocessing = "0"
end
unless embed_phase.files_references.any? { |fr| fr.path == "#{WIDGET_NAME}.appex" }
  widget_product = widget_target.product_reference
  build_file = embed_phase.add_file_reference(widget_product)
  build_file.settings = { "ATTRIBUTES" => ["RemoveHeadersOnCopy"] }
  puts "  embedded #{WIDGET_NAME}.appex in #{ios_app.name}"
end

# Target dependency
unless ios_app.dependencies.any? { |d| d.target&.uuid == widget_target.uuid }
  ios_app.add_dependency(widget_target)
  puts "  #{ios_app.name} depends on #{WIDGET_NAME}"
end

# --- 3. Watch widget extension target -------------------------------------

WATCH_WIDGET_NAME   = "ReflectWatchWidget"
WATCH_WIDGET_BUNDLE = "com.MarkFriedlander.Reflect.watchkitapp.complication"

watch_widget_target = find_target(proj, WATCH_WIDGET_NAME)
if watch_widget_target.nil?
  puts "Creating target: #{WATCH_WIDGET_NAME}"
  watch_widget_target = proj.new_target(
    :watch2_extension,
    WATCH_WIDGET_NAME,
    :watchos,
    watch_deploy,
    proj.products_group,
    :swift
  )
else
  puts "Target #{WATCH_WIDGET_NAME} exists — updating settings"
end

watch_widget_group = find_or_create_sync_group(proj, "WatchWidget")
link_sync_group(watch_widget_target, watch_widget_group)
link_sync_group(watch_widget_target, shared_group)
exclude_files_from_target(proj, watch_widget_group, watch_widget_target, ["Info.plist"])

watch_widget_target.build_configurations.each do |bc|
  bs = bc.build_settings
  bs["PRODUCT_BUNDLE_IDENTIFIER"]      = WATCH_WIDGET_BUNDLE
  bs["PRODUCT_NAME"]                   = "$(TARGET_NAME)"
  bs["INFOPLIST_FILE"]                 = "WatchWidget/Info.plist"
  bs["WATCHOS_DEPLOYMENT_TARGET"]      = watch_deploy
  bs["TARGETED_DEVICE_FAMILY"]         = "4"
  bs["SWIFT_VERSION"]                  = swift_ver
  bs["GENERATE_INFOPLIST_FILE"]        = "NO"
  bs["DEVELOPMENT_TEAM"]               = TEAM_ID
  bs["CODE_SIGN_STYLE"]                = "Automatic"
  bs["SKIP_INSTALL"]                   = "YES"
  bs["LD_RUNPATH_SEARCH_PATHS"]        = "$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks"
  bs["MARKETING_VERSION"]              = "1.0"
  bs["CURRENT_PROJECT_VERSION"]        = "1"
  bs["ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS"] = "NO"
end

# Embed in Watch app
watch_embed = watch_app.copy_files_build_phases.find { |p| p.name == "Embed App Extensions" }
if watch_embed.nil?
  watch_embed = watch_app.new_copy_files_build_phase("Embed App Extensions")
  watch_embed.symbol_dst_subfolder_spec = :plug_ins
  watch_embed.run_only_for_deployment_postprocessing = "0"
end
unless watch_embed.files_references.any? { |fr| fr.path == "#{WATCH_WIDGET_NAME}.appex" }
  watch_widget_product = watch_widget_target.product_reference
  build_file = watch_embed.add_file_reference(watch_widget_product)
  build_file.settings = { "ATTRIBUTES" => ["RemoveHeadersOnCopy"] }
  puts "  embedded #{WATCH_WIDGET_NAME}.appex in #{watch_app.name}"
end

unless watch_app.dependencies.any? { |d| d.target&.uuid == watch_widget_target.uuid }
  watch_app.add_dependency(watch_widget_target)
  puts "  #{watch_app.name} depends on #{WATCH_WIDGET_NAME}"
end

# --- 4. Save ---------------------------------------------------------------

proj.save
puts "Saved #{PROJ_PATH}"
