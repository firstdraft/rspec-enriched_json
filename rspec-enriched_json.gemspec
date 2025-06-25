# frozen_string_literal: true

require_relative "lib/rspec/enriched_json/version"

Gem::Specification.new do |spec|
  spec.name = "rspec-enriched_json"
  spec.version = RSpec::EnrichedJson::VERSION
  spec.authors = ["Raghu Betina"]
  spec.email = ["raghu@firstdraft.com"]
  spec.homepage = "https://github.com/raghubetina/rspec-enriched_json"
  spec.summary = "Enriches RSpec JSON output with structured failure data"
  spec.description = "A drop-in replacement for RSpec's built-in JSON formatter that adds structured test failure data, making it easy to programmatically analyze test results."
  spec.license = "MIT"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/raghubetina/rspec-enriched_json/issues",
    "changelog_uri" => "https://github.com/raghubetina/rspec-enriched_json/blob/main/CHANGELOG.md",
    "homepage_uri" => "https://github.com/raghubetina/rspec-enriched_json",
    "rubygems_mfa_required" => "true",
    "source_code_uri" => "https://github.com/raghubetina/rspec-enriched_json"
  }

  spec.required_ruby_version = ">= 2.7.0"
  spec.add_dependency "rspec-core", ">= 3.0"
  spec.add_dependency "rspec-expectations", ">= 3.0"

  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "standard", "~> 1.0"

  spec.extra_rdoc_files = Dir["README*", "LICENSE*"]
  spec.files = Dir["*.gemspec", "lib/**/*"]
end
