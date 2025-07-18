# frozen_string_literal: true

require "spec_helper"
require "json"
require "tempfile"

RSpec.describe "Passing test value capture" do
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
    output = StringIO.new

    # Run the tests with our formatter
    RSpec::Core::Runner.run(
      [test_file.path, "--format", "RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter"],
      $stderr,
      output
    )

    json_output = JSON.parse(output.string)
    examples = json_output["examples"]

    # Test 1: eq matcher
    eq_test = examples.find { |e| e["description"] == "captures values for eq matcher" }
    expect(eq_test["status"]).to eq("passed")
    expect(eq_test).to have_key("details")
    expect(JSON.parse(eq_test["details"]["expected"])).to eq(42)
    expect(JSON.parse(eq_test["details"]["actual"])).to eq(42)
    expect(eq_test["details"]["matcher_name"]).to eq("RSpec::Matchers::BuiltIn::Eq")
    expect(eq_test["details"]["passed"]).to be true

    # Test 2: be matcher
    be_test = examples.find { |e| e["description"] == "captures values for be matcher" }
    expect(be_test["status"]).to eq("passed")
    expect(be_test).to have_key("details")
    expect(JSON.parse(be_test["details"]["expected"])).to be true
    expect(JSON.parse(be_test["details"]["actual"])).to be true
    expect(be_test["details"]["matcher_name"]).to eq("RSpec::Matchers::BuiltIn::Be")

    # Test 3: include matcher
    include_test = examples.find { |e| e["description"] == "captures values for include matcher" }
    expect(include_test["status"]).to eq("passed")
    expect(include_test).to have_key("details")
    expect(JSON.parse(include_test["details"]["expected"])).to eq(2)
    expect(JSON.parse(include_test["details"]["actual"])).to eq([1, 2, 3])
    expect(include_test["details"]["matcher_name"]).to eq("RSpec::Matchers::BuiltIn::Include")

    # Test 4: match matcher
    match_test = examples.find { |e| e["description"] == "captures values for match matcher" }
    expect(match_test["status"]).to eq("passed")
    expect(match_test).to have_key("details")
    # Regex serializes differently, just check it exists
    expect(match_test["details"]["expected"]).not_to be_nil
    expect(JSON.parse(match_test["details"]["actual"])).to eq("hello world")
    expect(match_test["details"]["matcher_name"]).to eq("RSpec::Matchers::BuiltIn::Match")

    # Test 5: negated matcher
    negated_test = examples.find { |e| e["description"] == "captures values for negated matchers" }
    expect(negated_test["status"]).to eq("passed")
    expect(negated_test).to have_key("details")
    expect(JSON.parse(negated_test["details"]["expected"])).to eq(10)
    expect(JSON.parse(negated_test["details"]["actual"])).to eq(5)
    expect(negated_test["details"]["negated"]).to be true

    # Test 6: complex objects
    complex_test = examples.find { |e| e["description"] == "captures values for complex objects" }
    expect(complex_test["status"]).to eq("passed")
    expect(complex_test).to have_key("details")
    expected_hash = JSON.parse(complex_test["details"]["expected"])
    expect(expected_hash["name"]).to eq("Alice")
    expect(expected_hash["age"]).to eq(30)

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
    expect(JSON.parse(failing_test["details"]["expected"])).to eq(2)
    expect(JSON.parse(failing_test["details"]["actual"])).to eq(1)
    expect(failing_test["details"]["passed"]).to be_falsey
  end

  it "includes passed field to distinguish from failing tests" do
    test_file_2 = Tempfile.new(["passed_field_test", ".rb"]).tap do |f|
      f.write(<<~RUBY)
        require 'rspec'
        require 'rspec/enriched_json'

        RSpec.describe "Passed field test" do
          it "marks passing test with passed: true" do
            expect(1).to eq(1)
          end
        end
      RUBY
      f.close
    end

    output = StringIO.new

    RSpec::Core::Runner.run(
      [test_file_2.path, "--format", "RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter"],
      $stderr,
      output
    )

    json_output = JSON.parse(output.string)
    example = json_output["examples"].first

    expect(example["details"]["passed"]).to be true

    test_file_2.unlink
  end

  it "memory cleanup doesn't interfere with value capture" do
    output = StringIO.new

    # Run tests and ensure values are captured before cleanup
    RSpec::Core::Runner.run(
      [test_file.path, "--format", "RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter"],
      $stderr,
      output
    )

    json_output = JSON.parse(output.string)

    # All passing tests should have details captured
    passing_tests = json_output["examples"].select { |e| e["status"] == "passed" }
    expect(passing_tests).not_to be_empty
    expect(passing_tests.all? { |test| test.key?("details") }).to be true
  end
end

