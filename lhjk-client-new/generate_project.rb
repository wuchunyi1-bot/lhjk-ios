#!/usr/bin/env ruby
# Generates a complete project.pbxproj for lhjk-client-new
require 'securerandom'

PROJECT_DIR = File.expand_path(File.dirname(__FILE__))
SRC_ROOT = File.join(PROJECT_DIR, 'lhjk-client-new')

# Collect all source files relative to SRC_ROOT
swift_files = Dir.glob(File.join(SRC_ROOT, '**', '*.swift')).sort.map { |f| f.sub(SRC_ROOT + '/', '') }

# Collect resource files
resource_files = []
# Info.plist
resource_files << 'Other/Resources/Info.plist' if File.exist?(File.join(SRC_ROOT, 'Other/Resources/Info.plist'))
# LaunchScreen.storyboard
resource_files << 'Other/Resources/LaunchScreen.storyboard' if File.exist?(File.join(SRC_ROOT, 'Other/Resources/LaunchScreen.storyboard'))
# Assets.xcassets (folder reference)
resource_files << 'Other/Resources/Assets.xcassets' if File.exist?(File.join(SRC_ROOT, 'Other/Resources/Assets.xcassets'))

$counter = 0
def new_id
  $counter += 1
  "%024X" % $counter
end

# ---- Generate IDs ----
# File reference IDs
file_ref_ids = {}
swift_files.each { |f| file_ref_ids[f] = new_id }
resource_files.each { |f| file_ref_ids[f] = new_id }

# Build file IDs (for Sources build phase)
build_file_ids = {}
swift_files.each { |f| build_file_ids[f] = new_id }
resource_files.each { |f| build_file_ids[f] = new_id }

# Group IDs
group_ids = {}
%w[PL BLL DAL Other].each { |g| group_ids[g] = new_id }
%w[PL/Health PL/Home PL/Message PL/My PL/RegisterLogin PL/Service].each { |g| group_ids[g] = new_id }
%w[BLL/Health BLL/Home BLL/Message BLL/My BLL/RegisterLogin BLL/Service].each { |g| group_ids[g] = new_id }
%w[DAL/Networking DAL/Bluetooth DAL/IM DAL/Payment DAL/Storage DAL/Router].each { |g| group_ids[g] = new_id }
%w[Other/Common Other/Resources].each { |g| group_ids[g] = new_id }
%w[Other/Common/Base Other/Common/Extensions Other/Common/Protocols].each { |g| group_ids[g] = new_id }

# Build phase IDs
sources_build_phase_id = new_id
resources_build_phase_id = new_id
frameworks_build_phase_id = new_id
cp_check_pods_id = new_id
cp_embed_pods_id = new_id
cp_copy_resources_id = new_id

# Target ID
target_id = new_id
product_ref_id = new_id

# Project ID
project_id = new_id

# Pods references
pods_framework_ref_id = new_id
pods_debug_xcconfig_id = new_id
pods_release_xcconfig_id = new_id

# Configuration list IDs
project_config_list_id = new_id
target_config_list_id = new_id

# Build configuration IDs
project_debug_config_id = new_id
project_release_config_id = new_id
target_debug_config_id = new_id
target_release_config_id = new_id

# Extra groups
main_group_id = new_id
products_group_id = new_id
frameworks_group_id = new_id
pods_group_id = new_id

# ---- Helper to generate PBX sections ----
def pbx_file_ref(id, name, path, type, source_tree = '<group>')
  extras = ''
  if type == 'folder.assetcatalog'
    extras = " lastKnownFileType = folder.assetcatalog;"
  elsif type == 'file.storyboard'
    extras = " lastKnownFileType = file.storyboard;"
  elsif type == 'text.plist.xml'
    extras = " lastKnownFileType = text.plist.xml;"
  elsif type == 'sourcecode.swift'
    extras = " lastKnownFileType = sourcecode.swift;"
  elsif type == 'wrapper.framework'
    extras = " explicitFileType = wrapper.framework; includeInIndex = 0;"
  elsif type == 'wrapper.application'
    extras = " explicitFileType = wrapper.application; includeInIndex = 0;"
  elsif type == 'text.xcconfig'
    extras = " includeInIndex = 1; lastKnownFileType = text.xcconfig;"
  end
  "\t\t#{id} /* #{name} */ = {isa = PBXFileReference;#{extras} path = \"#{path}\"; sourceTree = \"#{source_tree}\"; };"
end

def pbx_build_file(id, ref_id, name)
  "\t\t#{id} /* #{name} in Sources */ = {isa = PBXBuildFile; fileRef = #{ref_id}; };"
end

def pbx_build_file_resources(id, ref_id, name)
  "\t\t#{id} /* #{name} in Resources */ = {isa = PBXBuildFile; fileRef = #{ref_id}; };"
end

def pbx_group(id, name, children_ids, source_tree = '"<group>"', path = nil)
  children_str = children_ids.map { |c| "\t\t\t\t#{c}," }.join("\n")
  path_str = path ? " path = \"#{path}\";" : ""
  "\t\t#{id} /* #{name} */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n#{children_str}\n\t\t\t);#{path_str}\n\t\t\tname = #{name};\n\t\t\tsourceTree = #{source_tree};\n\t\t};"
end

# ---- Generate content ----

output = <<~HEADER
// !$*UTF8*$!
{
\tarchiveVersion = 1;
\tclasses = {
\t};
\tobjectVersion = 56;
\tobjects = {

HEADER

# ---- PBXBuildFile section ----
output << "\n/* Begin PBXBuildFile section */\n"

# Pods framework
output << "\t\t#{build_file_ids.values.first} /* Pods_lhjk_client_new.framework in Frameworks */ = {isa = PBXBuildFile; fileRef = #{pods_framework_ref_id} /* Pods_lhjk_client_new.framework */; };\n"

# Source build files
swift_files.each do |f|
  name = File.basename(f)
  output << pbx_build_file(build_file_ids[f], file_ref_ids[f], name) + "\n"
end

# Resource build files
resource_files.each do |f|
  name = File.basename(f)
  rf_id = new_id
  # Use a different ID for resource build files
  build_file_ids["RES_#{f}"] = rf_id
  output << pbx_build_file_resources(rf_id, file_ref_ids[f], name) + "\n"
end

output << "/* End PBXBuildFile section */\n"

# ---- PBXFileReference section ----
output << "\n/* Begin PBXFileReference section */\n"

# Product
output << pbx_file_ref(product_ref_id, 'lhjk-client-new.app', 'lhjk-client-new.app', 'wrapper.application', 'BUILT_PRODUCTS_DIR') + "\n"

# Pods framework
output << pbx_file_ref(pods_framework_ref_id, 'Pods_lhjk_client_new.framework', 'Pods_lhjk_client_new.framework', 'wrapper.framework', 'BUILT_PRODUCTS_DIR') + "\n"

# Pods xcconfigs
output << pbx_file_ref(pods_debug_xcconfig_id, 'Pods-lhjk-client-new.debug.xcconfig', 'Pods-lhjk-client-new.debug.xcconfig', 'text.xcconfig') + "\n"
output << pbx_file_ref(pods_release_xcconfig_id, 'Pods-lhjk-client-new.release.xcconfig', 'Pods-lhjk-client-new.release.xcconfig', 'text.xcconfig') + "\n"

# Source files
swift_files.each do |f|
  name = File.basename(f)
  output << pbx_file_ref(file_ref_ids[f], name, name, 'sourcecode.swift') + "\n"
end

# Resource files
resource_files.each do |f|
  name = File.basename(f)
  ext = File.extname(f)
  type = case ext
         when '.storyboard' then 'file.storyboard'
         when '.plist' then 'text.plist.xml'
         else
           if f.include?('Assets.xcassets')
             'folder.assetcatalog'
           else
             'text'
           end
         end
  output << pbx_file_ref(file_ref_ids[f], name, name, type) + "\n"
end

output << "/* End PBXFileReference section */\n"

# ---- PBXGroup section ----
output << "\n/* Begin PBXGroup section */\n"

# Products group
output << pbx_group(products_group_id, 'Products', [product_ref_id]) + "\n"

# Frameworks group
output << pbx_group(frameworks_group_id, 'Frameworks', [pods_framework_ref_id]) + "\n"

# Pods group
output << "\t\t#{pods_group_id} /* Pods */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t#{pods_debug_xcconfig_id} /* Pods-lhjk-client-new.debug.xcconfig */,\n\t\t\t\t#{pods_release_xcconfig_id} /* Pods-lhjk-client-new.release.xcconfig */,\n\t\t\t);\n\t\t\tname = Pods;\n\t\t\tpath = \"../Pods\";\n\t\t\tsourceTree = \"<group>\";\n\t\t};\n"

# Helper to create subgroup with files
def create_subgroup(id, name, path, file_refs, all_file_ref_ids, swift_files, base_path)
  children = []
  swift_files.each do |f|
    if f.start_with?(base_path + '/') && !f.sub(base_path + '/', '').include?('/')
      children << all_file_ref_ids[f]
    end
  end
  children_str = children.map { |c| "\t\t\t\t#{c}," }.join("\n")
  "\t\t#{id} /* #{name} */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n#{children_str}\n\t\t\t);\n\t\t\tpath = #{name};\n\t\t\tsourceTree = \"<group>\";\n\t\t};"
end

# BLL subgroups
%w[Health Home Message My RegisterLogin Service].each do |mod|
  output << create_subgroup(group_ids["BLL/#{mod}"], mod, mod, file_ref_ids, file_ref_ids, swift_files, "BLL/#{mod}") + "\n"
end

# DAL subgroups
%w[Networking Bluetooth IM Payment Storage Router].each do |mod|
  output << create_subgroup(group_ids["DAL/#{mod}"], mod, mod, file_ref_ids, file_ref_ids, swift_files, "DAL/#{mod}") + "\n"
end

# PL subgroups
%w[Health Home Message My RegisterLogin Service].each do |mod|
  output << create_subgroup(group_ids["PL/#{mod}"], mod, mod, file_ref_ids, file_ref_ids, swift_files, "PL/#{mod}") + "\n"
end

# Other subgroups
output << create_subgroup(group_ids['Other/Common/Base'], 'Base', 'Base', file_ref_ids, file_ref_ids, swift_files, 'Other/Common/Base') + "\n"
output << create_subgroup(group_ids['Other/Common/Extensions'], 'Extensions', 'Extensions', file_ref_ids, file_ref_ids, swift_files, 'Other/Common/Extensions') + "\n"
output << create_subgroup(group_ids['Other/Common/Protocols'], 'Protocols', 'Protocols', file_ref_ids, file_ref_ids, swift_files, 'Other/Common/Protocols') + "\n"

# Other/Common group
common_children = [group_ids['Other/Common/Base'], group_ids['Other/Common/Extensions'], group_ids['Other/Common/Protocols']]
output << pbx_group(group_ids['Other/Common'], 'Common', common_children) + "\n"

# Other/Resources group
res_children = resource_files.select { |f| f.start_with?('Other/Resources/') }.map { |f| file_ref_ids[f] }
other_swift_in_root = swift_files.select { |f| f.start_with?('Other/') && !f.include?('/') && f != 'Other/' }.map { |f| file_ref_ids[f] }
output << pbx_group(group_ids['Other/Resources'], 'Resources', res_children) + "\n"

# Other group (root level files + Common + Resources)
other_root_ids = swift_files.select { |f| f.start_with?('Other/') && !f.include?('/', f.index('/') + 1) rescue false }
# Actually, let me just check: files directly in Other/
other_direct_files = swift_files.select { |f|
  parts = f.split('/')
  parts[0] == 'Other' && parts.length == 2
}.map { |f| file_ref_ids[f] }
other_children = [group_ids['Other/Common'], group_ids['Other/Resources']] + other_direct_files
output << pbx_group(group_ids['Other'], 'Other', other_children, '"SOURCE_ROOT"', 'Other') + "\n"

# BLL group
bll_mod_ids = %w[Health Home Message My RegisterLogin Service].map { |m| group_ids["BLL/#{m}"] }
output << pbx_group(group_ids['BLL'], 'BLL', bll_mod_ids, '"SOURCE_ROOT"', 'BLL') + "\n"

# DAL group
dal_mod_ids = %w[Networking Bluetooth IM Payment Storage Router].map { |m| group_ids["DAL/#{m}"] }
output << pbx_group(group_ids['DAL'], 'DAL', dal_mod_ids, '"SOURCE_ROOT"', 'DAL') + "\n"

# PL group
pl_mod_ids = %w[Health Home Message My RegisterLogin Service].map { |m| group_ids["PL/#{m}"] }
output << pbx_group(group_ids['PL'], 'PL', pl_mod_ids, '"SOURCE_ROOT"', 'PL') + "\n"

# Main group
main_children = [group_ids['Other'], group_ids['PL'], group_ids['BLL'], group_ids['DAL'], products_group_id, frameworks_group_id, pods_group_id]
output << "\t\t#{main_group_id} /* lhjk-client-new */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n"
main_children.each { |c| output << "\t\t\t\t#{c},\n" }
output << "\t\t\t);\n\t\t\tpath = \"lhjk-client-new\";\n\t\t\tsourceTree = \"<group>\";\n\t\t};\n"

output << "/* End PBXGroup section */\n"

# ---- PBXNativeTarget section ----
output << "\n/* Begin PBXNativeTarget section */\n"
output << "\t\t#{target_id} /* lhjk-client-new */ = {\n"
output << "\t\t\tisa = PBXNativeTarget;\n"
output << "\t\t\tbuildConfigurationList = #{target_config_list_id} /* Build configuration list for PBXNativeTarget \"lhjk-client-new\" */;\n"
output << "\t\t\tbuildPhases = (\n"
output << "\t\t\t\t#{cp_check_pods_id} /* [CP] Check Pods Manifest.lock */,\n"
output << "\t\t\t\t#{sources_build_phase_id} /* Sources */,\n"
output << "\t\t\t\t#{frameworks_build_phase_id} /* Frameworks */,\n"
output << "\t\t\t\t#{resources_build_phase_id} /* Resources */,\n"
output << "\t\t\t\t#{cp_embed_pods_id} /* [CP] Embed Pods Frameworks */,\n"
output << "\t\t\t\t#{cp_copy_resources_id} /* [CP] Copy Pods Resources */,\n"
output << "\t\t\t);\n"
output << "\t\t\tbuildRules = (\n\t\t\t);\n"
output << "\t\t\tdependencies = (\n\t\t\t);\n"
output << "\t\t\tname = \"lhjk-client-new\";\n"
output << "\t\t\tproductName = \"lhjk-client-new\";\n"
output << "\t\t\tproductReference = #{product_ref_id} /* lhjk-client-new.app */;\n"
output << "\t\t\tproductType = \"com.apple.product-type.application\";\n"
output << "\t\t};\n"
output << "/* End PBXNativeTarget section */\n"

# ---- PBXProject section ----
output << "\n/* Begin PBXProject section */\n"
output << "\t\t#{project_id} /* Project object */ = {\n"
output << "\t\t\tisa = PBXProject;\n"
output << "\t\t\tattributes = {\n"
output << "\t\t\t\tLastSwiftUpdateCheck = 1620;\n"
output << "\t\t\t\tLastUpgradeCheck = 1620;\n"
output << "\t\t\t\tTargetAttributes = {\n"
output << "\t\t\t\t\t#{target_id} = {\n"
output << "\t\t\t\t\t\tProvisioningStyle = Automatic;\n"
output << "\t\t\t\t\t};\n"
output << "\t\t\t\t};\n"
output << "\t\t\t};\n"
output << "\t\t\tbuildConfigurationList = #{project_config_list_id} /* Build configuration list for PBXProject \"lhjk-client-new\" */;\n"
output << "\t\t\tcompatibilityVersion = \"Xcode 16.0\";\n"
output << "\t\t\tdevelopmentRegion = en;\n"
output << "\t\t\thasScannedForEncodings = 0;\n"
output << "\t\t\tknownRegions = (\n\t\t\t\ten,\n\t\t\t\tBase,\n\t\t\t);\n"
output << "\t\t\tmainGroup = #{main_group_id};\n"
output << "\t\t\tproductRefGroup = #{products_group_id} /* Products */;\n"
output << "\t\t\tprojectDirPath = \"\";\n"
output << "\t\t\tprojectRoot = \"\";\n"
output << "\t\t\ttargets = (\n"
output << "\t\t\t\t#{target_id} /* lhjk-client-new */,\n"
output << "\t\t\t);\n"
output << "\t\t};\n"
output << "/* End PBXProject section */\n"

# ---- PBXSourcesBuildPhase ----
output << "\n/* Begin PBXSourcesBuildPhase section */\n"
output << "\t\t#{sources_build_phase_id} /* Sources */ = {\n"
output << "\t\t\tisa = PBXSourcesBuildPhase;\n"
output << "\t\t\tbuildActionMask = 2147483647;\n"
output << "\t\t\tfiles = (\n"
swift_files.each do |f|
  name = File.basename(f)
  output << "\t\t\t\t#{build_file_ids[f]} /* #{name} in Sources */,\n"
end
output << "\t\t\t);\n"
output << "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
output << "\t\t};\n"
output << "/* End PBXSourcesBuildPhase section */\n"

# ---- PBXResourcesBuildPhase ----
output << "\n/* Begin PBXResourcesBuildPhase section */\n"
output << "\t\t#{resources_build_phase_id} /* Resources */ = {\n"
output << "\t\t\tisa = PBXResourcesBuildPhase;\n"
output << "\t\t\tbuildActionMask = 2147483647;\n"
output << "\t\t\tfiles = (\n"
resource_files.each do |f|
  name = File.basename(f)
  output << "\t\t\t\t#{build_file_ids["RES_#{f}"]} /* #{name} in Resources */,\n"
end
output << "\t\t\t);\n"
output << "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
output << "\t\t};\n"
output << "/* End PBXResourcesBuildPhase section */\n"

# ---- PBXFrameworksBuildPhase ----
output << "\n/* Begin PBXFrameworksBuildPhase section */\n"
output << "\t\t#{frameworks_build_phase_id} /* Frameworks */ = {\n"
output << "\t\t\tisa = PBXFrameworksBuildPhase;\n"
output << "\t\t\tbuildActionMask = 2147483647;\n"
output << "\t\t\tfiles = (\n"
output << "\t\t\t\t#{build_file_ids.values.first} /* Pods_lhjk_client_new.framework in Frameworks */,\n"
output << "\t\t\t);\n"
output << "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
output << "\t\t};\n"
output << "/* End PBXFrameworksBuildPhase section */\n"

# ---- PBXShellScriptBuildPhase ----
output << "\n/* Begin PBXShellScriptBuildPhase section */\n"

# Check Pods Manifest.lock
output << "\t\t#{cp_check_pods_id} /* [CP] Check Pods Manifest.lock */ = {\n"
output << "\t\t\tisa = PBXShellScriptBuildPhase;\n"
output << "\t\t\tbuildActionMask = 2147483647;\n"
output << "\t\t\tfiles = (\n\t\t\t);\n"
output << "\t\t\tinputFileListPaths = (\n\t\t\t);\n"
output << "\t\t\tinputPaths = (\n"
output << "\t\t\t\t\"${PODS_PODFILE_DIR_PATH}/Podfile.lock\",\n"
output << "\t\t\t\t\"${PODS_ROOT}/Manifest.lock\",\n"
output << "\t\t\t);\n"
output << "\t\t\tname = \"[CP] Check Pods Manifest.lock\";\n"
output << "\t\t\toutputFileListPaths = (\n\t\t\t);\n"
output << "\t\t\toutputPaths = (\n"
output << "\t\t\t\t\"$(DERIVED_FILE_DIR)/Pods-lhjk-client-new-checkManifestLockResult.txt\",\n"
output << "\t\t\t);\n"
output << "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
output << "\t\t\tshellPath = /bin/sh;\n"
output << "\t\t\tshellScript = \"diff \\\"\\${PODS_PODFILE_DIR_PATH}/Podfile.lock\\\" \\\"\\${PODS_ROOT}/Manifest.lock\\\" > /dev/null\\nif [ \\$? != 0 ] ; then\\n    echo \\\"error: The sandbox is not in sync with the Podfile.lock. Run 'pod install' or update your CocoaPods installation.\\\" >&2\\n    exit 1\\nfi\\n# This output is used by Xcode 'outputs' to avoid re-running this script phase.\\necho \\\"SUCCESS\\\" > \\\"\\${SCRIPT_OUTPUT_FILE_0}\\\"\\n\";\n"
output << "\t\t\tshowEnvVarsInLog = 0;\n"
output << "\t\t};\n"

# Embed Pods Frameworks
output << "\t\t#{cp_embed_pods_id} /* [CP] Embed Pods Frameworks */ = {\n"
output << "\t\t\tisa = PBXShellScriptBuildPhase;\n"
output << "\t\t\tbuildActionMask = 2147483647;\n"
output << "\t\t\tfiles = (\n\t\t\t);\n"
output << "\t\t\tinputPaths = (\n"
output << "\t\t\t\t\"${PODS_ROOT}/Target Support Files/Pods-lhjk-client-new/Pods-lhjk-client-new-frameworks.sh\",\n"
output << "\t\t\t);\n"
output << "\t\t\tname = \"[CP] Embed Pods Frameworks\";\n"
output << "\t\t\toutputPaths = (\n"
output << "\t\t\t);\n"
output << "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
output << "\t\t\tshellPath = /bin/sh;\n"
output << "\t\t\tshellScript = \"\\\"\\${PODS_ROOT}/Target Support Files/Pods-lhjk-client-new/Pods-lhjk-client-new-frameworks.sh\\\"\\n\";\n"
output << "\t\t\tshowEnvVarsInLog = 0;\n"
output << "\t\t};\n"

# Copy Pods Resources
output << "\t\t#{cp_copy_resources_id} /* [CP] Copy Pods Resources */ = {\n"
output << "\t\t\tisa = PBXShellScriptBuildPhase;\n"
output << "\t\t\tbuildActionMask = 2147483647;\n"
output << "\t\t\tfiles = (\n\t\t\t);\n"
output << "\t\t\tinputPaths = (\n"
output << "\t\t\t\t\"${PODS_ROOT}/Target Support Files/Pods-lhjk-client-new/Pods-lhjk-client-new-resources.sh\",\n"
output << "\t\t\t);\n"
output << "\t\t\tname = \"[CP] Copy Pods Resources\";\n"
output << "\t\t\toutputPaths = (\n"
output << "\t\t\t);\n"
output << "\t\t\trunOnlyForDeploymentPostprocessing = 0;\n"
output << "\t\t\tshellPath = /bin/sh;\n"
output << "\t\t\tshellScript = \"\\\"\\${PODS_ROOT}/Target Support Files/Pods-lhjk-client-new/Pods-lhjk-client-new-resources.sh\\\"\\n\";\n"
output << "\t\t\tshowEnvVarsInLog = 0;\n"
output << "\t\t};\n"

output << "/* End PBXShellScriptBuildPhase section */\n"

# ---- XCBuildConfiguration section ----
output << "\n/* Begin XCBuildConfiguration section */\n"

# Project Debug
output << "\t\t#{project_debug_config_id} /* Debug */ = {\n"
output << "\t\t\tisa = XCBuildConfiguration;\n"
output << "\t\t\tbuildSettings = {\n"
output << "\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;\n"
output << "\t\t\t\tCLANG_ANALYZER_NONNULL = YES;\n"
output << "\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;\n"
output << "\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++14\";\n"
output << "\t\t\t\tCLANG_CXX_LIBRARY = \"libc++\";\n"
output << "\t\t\t\tCLANG_ENABLE_MODULES = YES;\n"
output << "\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;\n"
output << "\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;\n"
output << "\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;\n"
output << "\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;\n"
output << "\t\t\t\tCLANG_WARN_COMMA = YES;\n"
output << "\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;\n"
output << "\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;\n"
output << "\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;\n"
output << "\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;\n"
output << "\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;\n"
output << "\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;\n"
output << "\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;\n"
output << "\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;\n"
output << "\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;\n"
output << "\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;\n"
output << "\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;\n"
output << "\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;\n"
output << "\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;\n"
output << "\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;\n"
output << "\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;\n"
output << "\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;\n"
output << "\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;\n"
output << "\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;\n"
output << "\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;\n"
output << "\t\t\t\tCOPY_PHASE_STRIP = NO;\n"
output << "\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;\n"
output << "\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;\n"
output << "\t\t\t\tENABLE_TESTABILITY = YES;\n"
output << "\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu11;\n"
output << "\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;\n"
output << "\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;\n"
output << "\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;\n"
output << "\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (\n\t\t\t\t\t\"DEBUG=1\",\n\t\t\t\t\t\"$(inherited)\",\n\t\t\t\t);\n"
output << "\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;\n"
output << "\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;\n"
output << "\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;\n"
output << "\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;\n"
output << "\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;\n"
output << "\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;\n"
output << "\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;\n"
output << "\t\t\t\tMTL_FAST_MATH = YES;\n"
output << "\t\t\t\tONLY_ACTIVE_ARCH = YES;\n"
output << "\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";\n"
output << "\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;\n"
output << "\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";\n"
output << "\t\t\t\tSWIFT_VERSION = 5.0;\n"
output << "\t\t\t};\n"
output << "\t\t\tname = Debug;\n"
output << "\t\t};\n"

# Project Release
output << "\t\t#{project_release_config_id} /* Release */ = {\n"
output << "\t\t\tisa = XCBuildConfiguration;\n"
output << "\t\t\tbuildSettings = {\n"
output << "\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;\n"
output << "\t\t\t\tCLANG_ANALYZER_NONNULL = YES;\n"
output << "\t\t\t\tCLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;\n"
output << "\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = \"gnu++14\";\n"
output << "\t\t\t\tCLANG_CXX_LIBRARY = \"libc++\";\n"
output << "\t\t\t\tCLANG_ENABLE_MODULES = YES;\n"
output << "\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;\n"
output << "\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;\n"
output << "\t\t\t\tCLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;\n"
output << "\t\t\t\tCLANG_WARN_BOOL_CONVERSION = YES;\n"
output << "\t\t\t\tCLANG_WARN_COMMA = YES;\n"
output << "\t\t\t\tCLANG_WARN_CONSTANT_CONVERSION = YES;\n"
output << "\t\t\t\tCLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;\n"
output << "\t\t\t\tCLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;\n"
output << "\t\t\t\tCLANG_WARN_DOCUMENTATION_COMMENTS = YES;\n"
output << "\t\t\t\tCLANG_WARN_EMPTY_BODY = YES;\n"
output << "\t\t\t\tCLANG_WARN_ENUM_CONVERSION = YES;\n"
output << "\t\t\t\tCLANG_WARN_INFINITE_RECURSION = YES;\n"
output << "\t\t\t\tCLANG_WARN_INT_CONVERSION = YES;\n"
output << "\t\t\t\tCLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;\n"
output << "\t\t\t\tCLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;\n"
output << "\t\t\t\tCLANG_WARN_OBJC_LITERAL_CONVERSION = YES;\n"
output << "\t\t\t\tCLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;\n"
output << "\t\t\t\tCLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;\n"
output << "\t\t\t\tCLANG_WARN_RANGE_LOOP_ANALYSIS = YES;\n"
output << "\t\t\t\tCLANG_WARN_STRICT_PROTOTYPES = YES;\n"
output << "\t\t\t\tCLANG_WARN_SUSPICIOUS_MOVE = YES;\n"
output << "\t\t\t\tCLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;\n"
output << "\t\t\t\tCLANG_WARN_UNREACHABLE_CODE = YES;\n"
output << "\t\t\t\tCLANG_WARN__DUPLICATE_METHOD_MATCH = YES;\n"
output << "\t\t\t\tCOPY_PHASE_STRIP = NO;\n"
output << "\t\t\t\tDEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";\n"
output << "\t\t\t\tENABLE_NS_ASSERTIONS = NO;\n"
output << "\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;\n"
output << "\t\t\t\tGCC_C_LANGUAGE_STANDARD = gnu11;\n"
output << "\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;\n"
output << "\t\t\t\tGCC_WARN_64_TO_32_BIT_CONVERSION = YES;\n"
output << "\t\t\t\tGCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;\n"
output << "\t\t\t\tGCC_WARN_UNDECLARED_SELECTOR = YES;\n"
output << "\t\t\t\tGCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;\n"
output << "\t\t\t\tGCC_WARN_UNUSED_FUNCTION = YES;\n"
output << "\t\t\t\tGCC_WARN_UNUSED_VARIABLE = YES;\n"
output << "\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;\n"
output << "\t\t\t\tMTL_FAST_MATH = YES;\n"
output << "\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";\n"
output << "\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Owholemodule\";\n"
output << "\t\t\t\tSWIFT_VERSION = 5.0;\n"
output << "\t\t\t};\n"
output << "\t\t\tname = Release;\n"
output << "\t\t};\n"

# Target Debug
output << "\t\t#{target_debug_config_id} /* Debug */ = {\n"
output << "\t\t\tisa = XCBuildConfiguration;\n"
output << "\t\t\tbaseConfigurationReference = #{pods_debug_xcconfig_id} /* Pods-lhjk-client-new.debug.xcconfig */;\n"
output << "\t\t\tbuildSettings = {\n"
output << "\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;\n"
output << "\t\t\t\tCODE_SIGN_STYLE = Automatic;\n"
output << "\t\t\t\tDEVELOPMENT_TEAM = \"\";\n"
output << "\t\t\t\tENABLE_DEBUG_DYLIB = NO;\n"
output << "\t\t\t\tGENERATE_INFOPLIST_FILE = NO;\n"
output << "\t\t\t\tINFOPLIST_FILE = \"Other/Resources/Info.plist\";\n"
output << "\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 15.0;\n"
output << "\t\t\t\tLD_RUNPATH_SEARCH_PATHS = \"$(inherited) @executable_path/Frameworks\";\n"
output << "\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.lhjk.client.new;\n"
output << "\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = \"\";\n"
output << "\t\t\t\tSDKROOT = iphoneos;\n"
output << "\t\t\t\tSWIFT_VERSION = 5.0;\n"
output << "\t\t\t\tTARGETED_DEVICE_FAMILY = 1;\n"
output << "\t\t\t};\n"
output << "\t\t\tname = Debug;\n"
output << "\t\t};\n"

# Target Release
output << "\t\t#{target_release_config_id} /* Release */ = {\n"
output << "\t\t\tisa = XCBuildConfiguration;\n"
output << "\t\t\tbaseConfigurationReference = #{pods_release_xcconfig_id} /* Pods-lhjk-client-new.release.xcconfig */;\n"
output << "\t\t\tbuildSettings = {\n"
output << "\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;\n"
output << "\t\t\t\tCODE_SIGN_STYLE = Automatic;\n"
output << "\t\t\t\tDEVELOPMENT_TEAM = \"\";\n"
output << "\t\t\t\tENABLE_DEBUG_DYLIB = NO;\n"
output << "\t\t\t\tGENERATE_INFOPLIST_FILE = NO;\n"
output << "\t\t\t\tINFOPLIST_FILE = \"Other/Resources/Info.plist\";\n"
output << "\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 15.0;\n"
output << "\t\t\t\tLD_RUNPATH_SEARCH_PATHS = \"$(inherited) @executable_path/Frameworks\";\n"
output << "\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.lhjk.client.new;\n"
output << "\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = \"\";\n"
output << "\t\t\t\tSDKROOT = iphoneos;\n"
output << "\t\t\t\tSWIFT_VERSION = 5.0;\n"
output << "\t\t\t\tTARGETED_DEVICE_FAMILY = 1;\n"
output << "\t\t\t\tVALIDATE_PRODUCT = YES;\n"
output << "\t\t\t};\n"
output << "\t\t\tname = Release;\n"
output << "\t\t};\n"

output << "/* End XCBuildConfiguration section */\n"

# ---- XCConfigurationList section ----
output << "\n/* Begin XCConfigurationList section */\n"

output << "\t\t#{project_config_list_id} /* Build configuration list for PBXProject \"lhjk-client-new\" */ = {\n"
output << "\t\t\tisa = XCConfigurationList;\n"
output << "\t\t\tbuildConfigurations = (\n"
output << "\t\t\t\t#{project_debug_config_id} /* Debug */,\n"
output << "\t\t\t\t#{project_release_config_id} /* Release */,\n"
output << "\t\t\t);\n"
output << "\t\t\tdefaultConfigurationIsVisible = 0;\n"
output << "\t\t\tdefaultConfigurationName = Release;\n"
output << "\t\t};\n"

output << "\t\t#{target_config_list_id} /* Build configuration list for PBXNativeTarget \"lhjk-client-new\" */ = {\n"
output << "\t\t\tisa = XCConfigurationList;\n"
output << "\t\t\tbuildConfigurations = (\n"
output << "\t\t\t\t#{target_debug_config_id} /* Debug */,\n"
output << "\t\t\t\t#{target_release_config_id} /* Release */,\n"
output << "\t\t\t);\n"
output << "\t\t\tdefaultConfigurationIsVisible = 0;\n"
output << "\t\t\tdefaultConfigurationName = Release;\n"
output << "\t\t};\n"

output << "/* End XCConfigurationList section */\n"

output << "\t};\n\trootObject = #{project_id} /* Project object */;\n}\n"

# Write output
pbxproj_dir = File.join(SRC_ROOT, 'lhjk-client-new.xcodeproj')
Dir.mkdir(pbxproj_dir) unless Dir.exist?(pbxproj_dir)
File.write(File.join(pbxproj_dir, 'project.pbxproj'), output)

puts "✅ Generated project.pbxproj with:"
puts "   - #{swift_files.length} Swift source files"
puts "   - #{resource_files.length} resource files"
puts "   - Total UUIDs: #{$counter}"
