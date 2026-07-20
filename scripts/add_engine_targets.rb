#!/usr/bin/env ruby
# Adds the Engine framework target and the EngineTests unit-test bundle to
# Tersten.xcodeproj (ticket #3). Idempotent: removes pre-existing targets/groups
# of the same name before recreating them.
require "xcodeproj"

PROJECT = File.expand_path("../Tersten/Tersten.xcodeproj", __dir__)
DEPLOYMENT = "15.0"
TEAM = "F3Y5649G7F"

project = Xcodeproj::Project.open(PROJECT)

# --- idempotency: tear down anything from a previous run -------------------
%w[EngineTests Engine].each do |name|
  project.targets.select { |t| t.name == name }.each(&:remove_from_project)
  grp = project.main_group.children.find { |c| c.display_name == name }
  grp&.remove_from_project
end

# --- Engine framework target ----------------------------------------------
engine = project.new_target(:framework, "Engine", :ios, DEPLOYMENT, nil, :swift)

engine_group = project.main_group.new_group("Engine", "Engine")
%w[TurkishAlphabet.swift Word.swift TileMark.swift Pattern.swift Lexicon.swift].each do |file|
  ref = engine_group.new_reference(file)
  engine.add_file_references([ref])
end

# Bundled Turkish word-list resources (#15). Copied into the framework bundle so
# Lexicon.bundled() can read them via a Bundle(for:)-anchored lookup — a
# framework target has no auto-generated Bundle.module. Produced by
# scripts/vendor_wordlists.rb.
resources_group = engine_group.new_group("Resources", "Resources")
%w[accept-tr.txt answers-tr.txt blocklist-tr.txt].each do |file|
  ref = resources_group.new_reference(file)
  engine.add_resources([ref])
end

engine.build_configurations.each do |config|
  s = config.build_settings
  s["PRODUCT_BUNDLE_IDENTIFIER"] = "com.iloverobots.terstenkelime.Engine"
  s["PRODUCT_NAME"] = "$(TARGET_NAME)"
  s["IPHONEOS_DEPLOYMENT_TARGET"] = DEPLOYMENT
  s["SWIFT_VERSION"] = "5.0"
  s["GENERATE_INFOPLIST_FILE"] = "YES"
  s["DEFINES_MODULE"] = "YES"
  s["TARGETED_DEVICE_FAMILY"] = "1,2"
  s["CODE_SIGN_STYLE"] = "Automatic"
  s["DEVELOPMENT_TEAM"] = TEAM
  s["CURRENT_PROJECT_VERSION"] = "1"
  s["MARKETING_VERSION"] = "1.0"
  s["SKIP_INSTALL"] = "YES"
  s["ENABLE_TESTABILITY"] = "YES" if config.name == "Debug"
end

# --- EngineTests unit-test bundle -----------------------------------------
tests = project.new_target(:unit_test_bundle, "EngineTests", :ios, DEPLOYMENT, nil, :swift)

tests_group = project.main_group.new_group("EngineTests", "EngineTests")
%w[CasingTests.swift WordTests.swift PatternTests.swift LexiconTests.swift].each do |file|
  ref = tests_group.new_reference(file)
  tests.add_file_references([ref])
end

# Depends only on the Engine (acceptance #4) — no app host, pure logic tests.
tests.add_dependency(engine)
tests.frameworks_build_phase.add_file_reference(engine.product_reference)

tests.build_configurations.each do |config|
  s = config.build_settings
  s["PRODUCT_BUNDLE_IDENTIFIER"] = "com.iloverobots.terstenkelime.EngineTests"
  s["PRODUCT_NAME"] = "$(TARGET_NAME)"
  s["IPHONEOS_DEPLOYMENT_TARGET"] = DEPLOYMENT
  s["SWIFT_VERSION"] = "5.0"
  s["GENERATE_INFOPLIST_FILE"] = "YES"
  s["TARGETED_DEVICE_FAMILY"] = "1,2"
  s["CODE_SIGN_STYLE"] = "Automatic"
  s["DEVELOPMENT_TEAM"] = TEAM
end

project.save

# --- shared scheme so `xcodebuild test -scheme Engine` works --------------
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(engine)
scheme.add_test_target(tests)
scheme.save_as(PROJECT, "Engine", true)

puts "OK: targets=#{project.targets.map(&:name).join(", ")}"
