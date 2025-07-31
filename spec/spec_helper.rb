# frozen_string_literal: true

require "bundler/setup"
require "rspec/enriched_json"
require "tempfile"
require "json"

RSpec.configure do |config|
  config.color = true
  config.disable_monkey_patching!
  config.example_status_persistence_file_path = "./tmp/rspec-examples.txt"
  config.filter_run_when_matching :focus
  config.formatter = (ENV.fetch("CI", false) == "true") ? :progress : :documentation
  config.order = :random
  config.pending_failure_output = :no_backtrace
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.warnings = true

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
    mocks.verify_partial_doubles = true
  end
end

def run_formatter_with_content(test_content)
  test_file = Tempfile.new(["test", ".rb"])
  test_file.write(test_content)
  test_file.flush

  output_file = Tempfile.new(["output", ".json"])

  # Run RSpec with our formatter
  system(
    "bundle", "exec", "rspec", test_file.path,
    "--format", "RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter",
    "--out", output_file.path,
    "-r", "./lib/rspec/enriched_json",
    err: File::NULL,
    out: File::NULL
  )

  JSON.parse(File.read(output_file.path))
ensure
  test_file&.close
  test_file&.unlink
  output_file&.close
  output_file&.unlink
end
