# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "json"

RSpec.describe "Metadata capture and error recovery" do
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

  describe "metadata capture" do
    it "captures location information" do
      test_content = <<~RUBY
        RSpec.describe "Example" do
          it "fails", :slow, :db, priority: :high do
            expect(1).to eq(2)
          end
        end
      RUBY

      output = run_formatter_with_content(test_content)
      example = output["examples"].first
      metadata = example["metadata"]

      expect(metadata).to include("location")
      expect(metadata).to include("absolute_file_path")
      expect(metadata).to include("rerun_file_path")
      expect(metadata["absolute_file_path"]).to start_with("/")
      expect(metadata["location"]).to match(/\.rb:\d+$/)
    end

    it "captures custom tags" do
      test_content = <<~RUBY
        RSpec.describe "Tagged tests" do
          it "has custom tags", :slow, :db, :focus, priority: :high, type: :integration do
            expect(true).to eq(false)
          end
        end
      RUBY

      output = run_formatter_with_content(test_content)
      tags = output["examples"].first["metadata"]["tags"]

      expect(tags).to eq({
        "slow" => true,
        "db" => true,
        "focus" => true,
        "priority" => "high",
        "type" => "integration"
      })
    end

    it "captures example group hierarchy" do
      test_content = <<~RUBY
        RSpec.describe "Outer" do
          describe "Middle" do
            context "Inner" do
              it "nested test" do
                expect(1).to eq(2)
              end
            end
          end
        end
      RUBY

      output = run_formatter_with_content(test_content)
      metadata = output["examples"].first["metadata"]

      expect(metadata["example_group"]).to eq("Inner")
      expect(metadata["example_group_hierarchy"]).to eq(["Outer", "Middle", "Inner"])
    end

    it "captures described class" do
      test_content = <<~RUBY
        class MyClass; end
        
        RSpec.describe MyClass do
          it "tests the class" do
            expect(1).to eq(2)
          end
        end
      RUBY

      output = run_formatter_with_content(test_content)
      metadata = output["examples"].first["metadata"]

      expect(metadata["described_class"]).to eq("MyClass")
    end
  end

  # Note: Error recovery is built into the serialization logic in ExpectationHelperWrapper::Serializer
  # Objects that fail to serialize will return error information instead of crashing
  # This is tested indirectly through the edge case specs
end

