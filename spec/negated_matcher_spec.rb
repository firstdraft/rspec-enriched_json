require "spec_helper"
require "json"

RSpec.describe "Negated matcher handling" do
  let(:output) { StringIO.new }
  let(:formatter) { RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter.new(output) }


  context "integration with formatter" do
    it "includes negated flag in JSON output" do
      # Create a separate configuration to avoid affecting global state
      config = RSpec::Core::Configuration.new
      config.add_formatter(formatter)

      reporter = RSpec::Core::Reporter.new(config)
      reporter.register_listener(formatter, :message, :dump_summary, :dump_profile, :stop, :seed, :close)

      example_group = RSpec.describe "Negated tests" do
        it "negated failure" do
          expect(true).not_to be true
        end

        it "regular failure" do
          expect(false).to be true
        end
      end

      reporter.start(2)
      example_group.run(reporter)
      reporter.finish

      output.rewind
      result = JSON.parse(output.read)

      negated_example = result["examples"].find { |ex| ex["description"] == "negated failure" }
      regular_example = result["examples"].find { |ex| ex["description"] == "regular failure" }

      expect(negated_example["details"]["negated"]).to eq(true)
      expect(regular_example["details"]["negated"]).to eq(false)
    end
  end

  context "with passing tests that have negated expectations" do
    it "captures negated flag for passing not_to tests" do
      RSpec::EnrichedJson.clear_test_values

      example_group = RSpec.describe do
        it "passes with not_to" do
          expect(5).not_to eq(6)
        end
      end

      example = example_group.examples.first
      example_group.run(RSpec.configuration.reporter)

      key = example.id
      captured_values = RSpec::EnrichedJson.all_test_values[key]

      expect(captured_values).to include(
        negated: true,
        passed: true,
        expected: "6",
        actual: "5"
      )
    end

    it "captures negated flag for passing regular tests" do
      RSpec::EnrichedJson.clear_test_values

      example_group = RSpec.describe do
        it "passes with regular to" do
          expect(5).to eq(5)
        end
      end

      example = example_group.examples.first
      example_group.run(RSpec.configuration.reporter)

      key = example.id
      captured_values = RSpec::EnrichedJson.all_test_values[key]

      expect(captured_values).not_to include(:negated) # Should not have negated key for positive expectations
      expect(captured_values).to include(
        passed: true,
        expected: "5",
        actual: "5"
      )
    end
  end
end
