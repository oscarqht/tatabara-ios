#!/usr/bin/env ruby
# frozen_string_literal: true

require "xcodeproj"

ROOT = File.expand_path("..", __dir__)
PROJECT_PATH = File.join(ROOT, "Tatabara.xcodeproj")

project = Xcodeproj::Project.new(PROJECT_PATH)
project.root_object.attributes["LastSwiftUpdateCheck"] = "2640"
project.root_object.attributes["LastUpgradeCheck"] = "2640"

app_target = project.new_target(:application, "Tatabara", :ios, "18.0")
tests_target = project.new_target(:unit_test_bundle, "TatabaraTests", :ios, "18.0")
ui_tests_target = project.new_target(:ui_test_bundle, "TatabaraUITests", :ios, "18.0")

[app_target, tests_target, ui_tests_target].each do |target|
  target.build_configurations.each do |config|
    config.build_settings["SWIFT_VERSION"] = "6.0"
    config.build_settings["IPHONEOS_DEPLOYMENT_TARGET"] = "18.0"
    config.build_settings["CODE_SIGN_STYLE"] = "Automatic"
    config.build_settings["TARGETED_DEVICE_FAMILY"] = "1"
    config.build_settings["CURRENT_PROJECT_VERSION"] = "1"
    config.build_settings["MARKETING_VERSION"] = "1.0"
    config.build_settings["GENERATE_INFOPLIST_FILE"] = "NO"
  end
end

app_target.build_configurations.each do |config|
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.tatabara.app"
  config.build_settings["INFOPLIST_FILE"] = "Tatabara/Info.plist"
  config.build_settings["ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME"] = "AccentColor"
  config.build_settings["ASSETCATALOG_COMPILER_APPICON_NAME"] = "AppIcon"
  config.build_settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  config.build_settings["INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents"] = "YES"
  config.build_settings["DEVELOPMENT_ASSET_PATHS"] = "\"Tatabara/PreviewContent\""
end

tests_target.build_configurations.each do |config|
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.tatabara.appTests"
  config.build_settings["GENERATE_INFOPLIST_FILE"] = "YES"
  config.build_settings["TEST_HOST"] = "$(BUILT_PRODUCTS_DIR)/Tatabara.app/Tatabara"
  config.build_settings["BUNDLE_LOADER"] = "$(TEST_HOST)"
  config.build_settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
end

ui_tests_target.build_configurations.each do |config|
  config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.tatabara.appUITests"
  config.build_settings["GENERATE_INFOPLIST_FILE"] = "YES"
  config.build_settings["TEST_TARGET_NAME"] = "Tatabara"
  config.build_settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
end

tests_target.add_dependency(app_target)
ui_tests_target.add_dependency(app_target)

main_group = project.main_group
app_group = main_group.new_group("Tatabara", "Tatabara")
tests_group = main_group.new_group("TatabaraTests", "TatabaraTests")
ui_tests_group = main_group.new_group("TatabaraUITests", "TatabaraUITests")

def add_files(group, path, target, file_types: [".swift"], resource_types: [])
  Dir.glob(File.join(path, "**", "*")).sort.each do |file_path|
    next if File.directory?(file_path)

    extension = File.extname(file_path)
    relative_path = file_path.delete_prefix("#{path}/")
    file_ref = group.find_file_by_path(relative_path) || group.new_file(relative_path)

    if file_types.include?(extension)
      target.add_file_references([file_ref])
    elsif resource_types.include?(extension)
      target.resources_build_phase.add_file_reference(file_ref, true)
    end
  end
end

add_files(app_group, File.join(ROOT, "Tatabara"), app_target, file_types: [".swift"], resource_types: [".wav", ".ttf", ".png"])
add_files(tests_group, File.join(ROOT, "TatabaraTests"), tests_target)
add_files(ui_tests_group, File.join(ROOT, "TatabaraUITests"), ui_tests_target)

assets_ref = app_group.find_file_by_path("Assets.xcassets") || app_group.new_file("Assets.xcassets")
preview_ref = app_group.find_file_by_path("PreviewContent") || app_group.new_file("PreviewContent")
app_target.resources_build_phase.add_file_reference(assets_ref, true)
app_target.resources_build_phase.add_file_reference(preview_ref, true)

scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(app_target)
scheme.set_launch_target(app_target)
scheme.test_action.add_testable(Xcodeproj::XCScheme::TestAction::TestableReference.new(tests_target))
scheme.test_action.add_testable(Xcodeproj::XCScheme::TestAction::TestableReference.new(ui_tests_target))
scheme.save_as(PROJECT_PATH, "Tatabara", true)

unit_scheme = Xcodeproj::XCScheme.new
unit_scheme.add_build_target(app_target)
unit_scheme.add_build_target(tests_target)
unit_scheme.set_launch_target(app_target)
unit_scheme.test_action.add_testable(Xcodeproj::XCScheme::TestAction::TestableReference.new(tests_target))
unit_scheme.save_as(PROJECT_PATH, "TatabaraUnitTests", true)

project.save
