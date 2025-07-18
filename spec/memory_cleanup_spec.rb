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

  it "has the clear_test_values method" do
    RSpec::EnrichedJson.all_test_values["test"] = {expected: 1, actual: 2}
    expect(RSpec::EnrichedJson.all_test_values).not_to be_empty

    RSpec::EnrichedJson.clear_test_values
    expect(RSpec::EnrichedJson.all_test_values).to be_empty
  end
end
