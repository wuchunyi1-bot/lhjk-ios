#!/usr/bin/env ruby
# Creates a fresh Xcode project using the xcodeproj gem
# Run with: /opt/homebrew/opt/ruby/bin/ruby create_project.rb

require 'rubygems'
require 'xcodeproj'

PROJECT_DIR = File.expand_path(File.dirname(__FILE__))
SRC_ROOT = File.join(PROJECT_DIR, 'lhjk-client-new')
PROJECT_NAME = 'lhjk-client-new'
TARGET_NAME = 'lhjk-client-new'
BUNDLE_ID = 'com.lhjk.client.new'

# Collect all Swift files (relative to SRC_ROOT)
swift_files = Dir.glob(File.join(SRC_ROOT, '**', '*.swift')).sort.map { |f| f.sub(SRC_ROOT + '/', '') }

# Collect resource files
resource_files = []
resource_files << 'Other/Resources/Info.plist' if File.exist?(File.join(SRC_ROOT, 'Other/Resources/Info.plist'))
resource_files << 'Other/Resources/LaunchScreen.storyboard' if File.exist?(File.join(SRC_ROOT, 'Other/Resources/LaunchScreen.storyboard'))
resource_files << 'Other/Resources/Assets.xcassets' if File.exist?(File.join(SRC_ROOT, 'Other/Resources/Assets.xcassets'))

puts "Creating project with #{swift_files.length} Swift files and #{resource_files.length} resources"

# Create project
project = Xcodeproj::Project.new("#{PROJECT_NAME}.xcodeproj")

# Create main group
main_group = project.main_group.find_subpath(PROJECT_NAME, true)
main_group.set_source_tree('SOURCE_ROOT')
main_group.set_path(PROJECT_NAME)

# Create target
target = project.new_target(:application, TARGET_NAME, :ios, '15.0')

# Set up build configurations
target.build_configurations.each do |config|
  config.build_settings['INFOPLIST_FILE'] = 'Other/Resources/Info.plist'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = BUNDLE_ID
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  config.build_settings['ENABLE_DEBUG_DYLIB'] = 'NO'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
end

# Add resource files
resources_group = main_group.find_subpath('Other/Resources', true)
resource_files.each do |f|
  full_path = File.join(SRC_ROOT, f)
  file_ref = resources_group.new_file(full_path)
  target.add_resources([file_ref])
end

# Organize source files into groups
# Group files by their directory structure
swift_files.each do |rel_path|
  full_path = File.join(SRC_ROOT, rel_path)
  # Get the directory part and filename
  dir_parts = rel_path.split('/')

  # Create group path (all parts except the filename)
  group_path = dir_parts[0..-2].join('/')
  group = main_group.find_subpath(group_path, true)

  # Add file to group and target
  file_ref = group.new_file(full_path)
  target.add_file_references([file_ref])
end

# Set up LaunchScreen as the launch storyboard
target.build_configurations.each do |config|
  config.build_settings['INFOPLIST_KEY_UILaunchStoryboardName'] = 'LaunchScreen'
end

# Save the project
project_path = File.join(PROJECT_DIR, 'lhjk-client-new', "#{PROJECT_NAME}.xcodeproj")
FileUtils.rm_rf(project_path) if Dir.exist?(project_path)
project.save(project_path)

puts "✅ Project created at: #{project_path}"
puts "   - #{swift_files.length} Swift source files"
puts "   - #{resource_files.length} resource files"
