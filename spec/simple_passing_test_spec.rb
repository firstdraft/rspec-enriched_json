# frozen_string_literal: true

require "spec_helper"
require "json"

RSpec.describe "Simple passing test capture" do
  before(:each) do
    # Clear test values before each test
    RSpec::EnrichedJson.clear_test_values
  end

  it "captures values for passing eq matcher" do
    # Run the expectation
    expect(42).to eq(42)

    # Check that values were captured
    captured_values = RSpec::EnrichedJson.all_test_values
    expect(captured_values).not_to be_empty

    # Get the captured value for this test
    test_key = RSpec.current_example.id
    test_values = captured_values[test_key]

    expect(test_values).not_to be_nil
    # Values are already JSON strings from Oj serialization
    expect(test_values[:expected]).to eq("42")
    expect(test_values[:actual]).to eq("42")
    expect(test_values[:matcher_name]).to eq("RSpec::Matchers::BuiltIn::Eq")
    expect(test_values[:passed]).to be true
  end

  it "captures values for passing include matcher" do
    # Run the expectation
    expect([1, 2, 3]).to include(2)

    # Check captured values
    test_key = RSpec.current_example.id
    test_values = RSpec::EnrichedJson.all_test_values[test_key]

    expect(test_values).not_to be_nil
    # Values are already JSON strings from Oj serialization
    expect(test_values[:expected]).to eq("2")
    # Oj serializes arrays with special format
    expect(test_values[:actual]).to include("1")
    expect(test_values[:actual]).to include("2")
    expect(test_values[:actual]).to include("3")
    expect(test_values[:matcher_name]).to eq("RSpec::Matchers::BuiltIn::Include")
    expect(test_values[:passed]).to be true
  end

  it "captures values for negated matchers" do
    # Run the expectation
    expect(5).not_to eq(10)

    # Check captured values
    test_key = RSpec.current_example.id
    test_values = RSpec::EnrichedJson.all_test_values[test_key]

    expect(test_values).not_to be_nil
    # Values are already JSON strings from Oj serialization
    expect(test_values[:expected]).to eq("10")
    expect(test_values[:actual]).to eq("5")
    expect(test_values[:negated]).to be true
    expect(test_values[:passed]).to be true
  end

  it "captures values for complex objects" do
    # Run the expectation
    expect({name: "Alice", age: 30}).to eq({name: "Alice", age: 30})

    # Check captured values
    test_key = RSpec.current_example.id
    test_values = RSpec::EnrichedJson.all_test_values[test_key]

    expect(test_values).not_to be_nil

    # Oj serializes hashes in object mode
    expect(test_values[:expected]).to include("Alice")
    expect(test_values[:expected]).to include("30")
    expect(test_values[:actual]).to include("Alice")
    expect(test_values[:actual]).to include("30")
    expect(test_values[:passed]).to be true
  end

  it "handles matchers without expected method" do
    # Run the expectation
    expect { 1 + 1 }.not_to raise_error

    # Check captured values
    test_key = RSpec.current_example.id
    test_values = RSpec::EnrichedJson.all_test_values[test_key]

    expect(test_values).not_to be_nil
    expect(test_values[:matcher_name]).to eq("RSpec::Matchers::BuiltIn::RaiseError")
    expect(test_values[:passed]).to be true
  end
end

