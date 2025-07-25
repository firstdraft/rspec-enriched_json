# frozen_string_literal: true

require "spec_helper"
require "json"
require "tempfile"

RSpec.describe "RSpec::EnrichedJson Integration" do
  def run_rspec_with_enriched_formatter(spec_content)
    # Create a temporary spec file
    spec_file = Tempfile.new(["test_spec", ".rb"])
    spec_file.write(spec_content)
    spec_file.close

    # Run RSpec with our formatter
    output = `cd #{File.dirname(spec_file.path)} && bundle exec rspec #{spec_file.path} --format RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter --no-color 2>/dev/null`

    spec_file.unlink

    JSON.parse(output)
  end

  it "enriches simple equality failures with structured data" do
    spec_content = <<~RUBY
      require 'rspec/enriched_json'
      
      RSpec.describe "Test" do
        it "fails with numbers" do
          expect(1 + 1).to eq(3)
        end
      end
    RUBY

    result = run_rspec_with_enriched_formatter(spec_content)

    example = result["examples"].first
    expect(example["status"]).to eq("failed")
    expect(example["details"]).to include(
      "expected" => "3",
      "actual" => "2",
      "matcher_name" => "RSpec::Matchers::BuiltIn::Eq"
    )
  end

  it "preserves custom failure messages" do
    spec_content = <<~RUBY
      require 'rspec/enriched_json'
      
      RSpec.describe "Test" do
        it "fails with custom message" do
          balance = 50
          required = 100
          expect(balance).to be >= required, "Insufficient funds"
        end
      end
    RUBY

    result = run_rspec_with_enriched_formatter(spec_content)

    example = result["examples"].first
    # Should preserve the original message that was overridden
    expect(example["details"]["original_message"]).to include("expected: >= 100")
  end

  it "adds structured data for passing tests" do
    spec_content = <<~RUBY
      require 'rspec/enriched_json'
      
      RSpec.describe "Test" do
        it "passes" do
          expect(1 + 1).to eq(2)
        end
      end
    RUBY

    result = run_rspec_with_enriched_formatter(spec_content)

    example = result["examples"].first
    expect(example["status"]).to eq("passed")
    # We now capture values for passing tests too
    expect(example).to have_key("details")
    expect(example["details"]["passed"]).to eq(true)
  end

  it "handles regular exceptions without structured data" do
    spec_content = <<~RUBY
      require 'rspec/enriched_json'
      
      RSpec.describe "Test" do
        it "raises an error" do
          raise NoMethodError, "undefined method"
        end
      end
    RUBY

    result = run_rspec_with_enriched_formatter(spec_content)

    example = result["examples"].first
    expect(example["status"]).to eq("failed")
    expect(example["exception"]["class"]).to eq("NoMethodError")
    expect(example).not_to have_key("details")
  end
end
