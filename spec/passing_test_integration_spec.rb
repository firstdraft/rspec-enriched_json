# frozen_string_literal: true

require "spec_helper"
require "json"
require "oj"
require "tempfile"
require "open3"

RSpec.describe "Passing test value capture integration" do
  # Use the same Oj options for loading that we use for dumping
  let(:oj_load_options) do
    {
      mode: :object,        # Restore Ruby objects and symbols
      auto_define: false,   # DON'T auto-create classes (safety)
      symbol_keys: false,   # Preserve symbols as they were serialized
      circular: true,       # Handle circular references
      create_additions: false, # Don't allow custom deserialization (safety)
      create_id: nil        # Disable create_id (safety)
    }
  end
  let(:test_file) do
    Tempfile.new(["passing_test", ".rb"]).tap do |f|
      f.write(<<~RUBY)
        require 'rspec'
        require 'rspec/enriched_json'

        RSpec.describe "Passing tests" do
          it "captures values for eq matcher" do
            expect(42).to eq(42)
          end

          it "captures values for be matcher" do
            expect(true).to be(true)
          end

          it "captures values for include matcher" do
            expect([1, 2, 3]).to include(2)
          end

          it "captures values for match matcher" do
            expect("hello world").to match(/world/)
          end

          it "captures values for negated matchers" do
            expect(5).not_to eq(10)
          end

          it "captures values for complex objects" do
            expect({name: "Alice", age: 30}).to eq({name: "Alice", age: 30})
          end

          it "handles matchers without expected method" do
            expect { 1 + 1 }.not_to raise_error
          end

          it "failing test for comparison" do
            expect(1).to eq(2)
          end
        end
      RUBY
      f.close
    end
  end

  after do
    test_file.unlink
  end

  it "captures expected and actual values for passing tests in JSON output" do
    # Run RSpec in a subprocess to avoid interference
    output_file = Tempfile.new(["output", ".json"])
    cmd = "bundle exec rspec #{test_file.path} --format RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter --out #{output_file.path} --no-color --order defined"
    system(cmd, out: File::NULL, err: File::NULL)

    json_output = JSON.parse(output_file.read)
    output_file.unlink
    examples = json_output["examples"]

    # Test 1: eq matcher
    eq_test = examples.find { |e| e["description"] == "captures values for eq matcher" }
    expect(eq_test["status"]).to eq("passed")
    expect(eq_test).to have_key("details")

    # Deserialize expected/actual values as the client does:
    # 1. JSON.parse to get the Oj string from double-encoded JSON
    # 2. Oj.load to get the actual Ruby object
    expected_json_str = JSON.parse(eq_test["details"]["expected"])
    actual_json_str = JSON.parse(eq_test["details"]["actual"])

    expect(Oj.load(expected_json_str, oj_load_options)).to eq(42)
    expect(Oj.load(actual_json_str, oj_load_options)).to eq(42)
    expect(eq_test["details"]["matcher_name"]).to eq("RSpec::Matchers::BuiltIn::Eq")
    expect(eq_test["details"]["passed"]).to be true  # Regular JSON value

    # Test 2: be matcher
    be_test = examples.find { |e| e["description"] == "captures values for be matcher" }
    expect(be_test["status"]).to eq("passed")
    expect(be_test).to have_key("details")

    # Same two-step deserialization
    expected_json_str = JSON.parse(be_test["details"]["expected"])
    actual_json_str = JSON.parse(be_test["details"]["actual"])

    expect(Oj.load(expected_json_str, oj_load_options)).to be true
    expect(Oj.load(actual_json_str, oj_load_options)).to be true
    expect(be_test["details"]["matcher_name"]).to eq("RSpec::Matchers::BuiltIn::Equal")

    # Test 3: include matcher
    include_test = examples.find { |e| e["description"] == "captures values for include matcher" }
    expect(include_test["status"]).to eq("passed")
    expect(include_test).to have_key("details")

    # Same two-step deserialization
    expected_json_str = JSON.parse(include_test["details"]["expected"])
    actual_json_str = JSON.parse(include_test["details"]["actual"])

    # Include matcher stores expected as an array
    expect(Oj.load(expected_json_str, oj_load_options)).to eq([2])
    expect(Oj.load(actual_json_str, oj_load_options)).to eq([1, 2, 3])
    expect(include_test["details"]["matcher_name"]).to eq("RSpec::Matchers::BuiltIn::Include")

    # Test 4: match matcher
    match_test = examples.find { |e| e["description"] == "captures values for match matcher" }
    expect(match_test["status"]).to eq("passed")
    expect(match_test).to have_key("details")

    # Same two-step deserialization
    expected_json_str = JSON.parse(match_test["details"]["expected"])
    actual_json_str = JSON.parse(match_test["details"]["actual"])

    # Regex cannot be fully deserialized with auto_define: false (security setting)
    # It becomes an uninitialized Regexp object
    expected_regex = Oj.load(expected_json_str, oj_load_options)
    expect(expected_regex).to be_a(Regexp)
    # Can't check source - it's uninitialized

    expect(Oj.load(actual_json_str, oj_load_options)).to eq("hello world")
    expect(match_test["details"]["matcher_name"]).to eq("RSpec::Matchers::BuiltIn::Match")

    # Test 5: negated matcher
    negated_test = examples.find { |e| e["description"] == "captures values for negated matchers" }
    expect(negated_test["status"]).to eq("passed")
    expect(negated_test).to have_key("details")

    # Same two-step deserialization
    expected_json_str = JSON.parse(negated_test["details"]["expected"])
    actual_json_str = JSON.parse(negated_test["details"]["actual"])

    expect(Oj.load(expected_json_str, oj_load_options)).to eq(10)
    expect(Oj.load(actual_json_str, oj_load_options)).to eq(5)
    expect(negated_test["details"]["negated"]).to be true  # Regular JSON boolean

    # Test 6: complex objects
    complex_test = examples.find { |e| e["description"] == "captures values for complex objects" }
    expect(complex_test["status"]).to eq("passed")
    expect(complex_test).to have_key("details")

    # Same two-step deserialization
    expected_json_str = JSON.parse(complex_test["details"]["expected"])
    actual_json_str = JSON.parse(complex_test["details"]["actual"])

    expected_hash = Oj.load(expected_json_str, oj_load_options)
    actual_hash = Oj.load(actual_json_str, oj_load_options)

    # Oj preserves symbol keys with mode: :object
    expect(expected_hash).to eq({name: "Alice", age: 30})
    expect(actual_hash).to eq({name: "Alice", age: 30})

    # Test 7: matchers without expected method
    no_expected_test = examples.find { |e| e["description"] == "handles matchers without expected method" }
    expect(no_expected_test["status"]).to eq("passed")
    expect(no_expected_test).to have_key("details")
    # Should still capture what it can
    expect(no_expected_test["details"]["matcher_name"]).to eq("RSpec::Matchers::BuiltIn::RaiseError")

    # Test 8: failing test should still have details
    failing_test = examples.find { |e| e["description"] == "failing test for comparison" }
    expect(failing_test["status"]).to eq("failed")
    expect(failing_test).to have_key("details")

    # Same two-step deserialization
    expected_json_str = JSON.parse(failing_test["details"]["expected"])
    actual_json_str = JSON.parse(failing_test["details"]["actual"])

    expect(Oj.load(expected_json_str, oj_load_options)).to eq(2)
    expect(Oj.load(actual_json_str, oj_load_options)).to eq(1)
    # Failed tests don't have passed field in details (it's in the exception)
  end

  it "includes passed field to distinguish passing from failing tests" do
    test_file_2 = Tempfile.new(["passed_field_test", ".rb"]).tap do |f|
      f.write(<<~RUBY)
        require 'rspec'
        require 'rspec/enriched_json'

        RSpec.describe "Passed field test" do
          it "marks passing test with passed: true" do
            expect(1).to eq(1)
          end
          
          it "marks failing test appropriately" do
            expect(1).to eq(2)
          end
        end
      RUBY
      f.close
    end

    output_file = Tempfile.new(["output", ".json"])
    cmd = "bundle exec rspec #{test_file_2.path} --format RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter --out #{output_file.path} --no-color"
    system(cmd, out: File::NULL, err: File::NULL)

    json_output = JSON.parse(output_file.read)
    output_file.unlink
    examples = json_output["examples"]

    passing_test = examples.find { |e| e["description"] == "marks passing test with passed: true" }
    expect(passing_test["details"]["passed"]).to be true  # Regular JSON boolean

    failing_test = examples.find { |e| e["description"] == "marks failing test appropriately" }
    # Failing tests have details in exception, not in top-level details
    expect(failing_test["exception"]).not_to be_nil

    test_file_2.unlink
  end

  it "memory cleanup doesn't interfere with value capture" do
    output_file = Tempfile.new(["output", ".json"])
    cmd = "bundle exec rspec #{test_file.path} --format RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter --out #{output_file.path} --no-color"
    system(cmd, out: File::NULL, err: File::NULL)

    json_output = JSON.parse(output_file.read)
    output_file.unlink

    # All passing tests should have details captured
    passing_tests = json_output["examples"].select { |e| e["status"] == "passed" }
    expect(passing_tests).not_to be_empty
    expect(passing_tests.all? { |test| test.key?("details") }).to be true
  end
end
