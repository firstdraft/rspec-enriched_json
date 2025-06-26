# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Safety limits for serialization" do
  it "truncates very long strings" do
    very_long_string = "x" * 2000

    begin
      expect(very_long_string).to eq("short")
    rescue RSpec::EnrichedJson::EnrichedExpectationNotMetError => e
      actual_data = e.details[:actual]
      expect(actual_data.length).to be <= 1100  # 1000 + "... (truncated)"
      expect(actual_data).to end_with("... (truncated)")
    end
  end

  it "handles large arrays" do
    large_array = (1..200).to_a

    begin
      expect(large_array).to eq([1, 2, 3])
    rescue RSpec::EnrichedJson::EnrichedExpectationNotMetError => e
      expect(e.details[:actual]).to eq("[Large array: 200 items]")
    end
  end

  it "handles deeply nested structures" do
    # Create a deeply nested structure
    deeply_nested = {a: {b: {c: {d: {e: {f: {g: "bottom"}}}}}}}

    begin
      expect(deeply_nested).to eq({})
    rescue RSpec::EnrichedJson::EnrichedExpectationNotMetError => e
      # Should serialize up to MAX_SERIALIZATION_DEPTH
      actual = e.details[:actual]
      expect(actual).to be_a(Hash)

      # Navigate to the depth limit
      current = actual
      5.times do |i|
        break unless current.is_a?(Hash) && current.values.first.is_a?(Hash)
        current = current.values.first
      end

      # At max depth, should see the truncation message
      expect(current.values.first).to eq("[Max depth exceeded]")
    end
  end

  it "handles objects with many instance variables" do
    class ManyVarsObject # rubocop:disable Lint/ConstantDefinitionInBlock
      def initialize
        15.times { |i| instance_variable_set("@var#{i}", i) }
      end
    end

    obj = ManyVarsObject.new

    begin
      expect(obj).to eq("something else")
    rescue RSpec::EnrichedJson::EnrichedExpectationNotMetError => e
      actual_data = e.details[:actual]
      # Instance variables are only included if <= 10
      # Since we have 15, they should not be included at all
      expect(actual_data["instance_variables"]).to be_nil
    end
  end
end
