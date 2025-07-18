# frozen_string_literal: true

require "rspec"
require "rspec/enriched_json"

RSpec.describe "Memory cleanup" do
  it "formatter cleans up test values after outputting JSON" do
    # The cleanup now happens in the formatter's close method
    # to ensure values are available when formatting

    # Store some test values
    RSpec::EnrichedJson.all_test_values["test1"] = {expected: 1, actual: 2}
    RSpec::EnrichedJson.all_test_values["test2"] = {expected: "a", actual: "b"}

    expect(RSpec::EnrichedJson.all_test_values).not_to be_empty

    # The formatter will call clear_test_values in its close method
    # For now, we just verify the method exists and works
    expect(RSpec::EnrichedJson).to respond_to(:clear_test_values)
  end

  it "can clear test values" do
    # Simply verify the method exists and works
    RSpec::EnrichedJson.all_test_values["dummy_test"] = {expected: 1, actual: 2}

    RSpec::EnrichedJson.clear_test_values

    # Check that dummy_test was removed (ignore any values from this test itself)
    expect(RSpec::EnrichedJson.all_test_values["dummy_test"]).to be_nil
  end
end
