# frozen_string_literal: true

require "spec_helper"
require "json"
require "oj"

RSpec.describe "Regex serialization" do
  it "serializes regex patterns correctly in integration test" do
    # Create a test file
    test_file = "spec/support/regex_test_integration.rb"
    File.write(test_file, <<~RUBY)
      RSpec.describe "Regex tests" do
        it "matches with case-insensitive regex" do
          expect("HELLO").to match(/hello/i)
        end
        
        it "matches with multiline regex" do
          expect("line1\\nline2").to match(/line1.line2/m)
        end
        
        it "includes regex in array" do
          expect(["test", "hello"]).to include(/world/)
        end
      end
    RUBY
    
    # Run the test with JSON formatter
    output = StringIO.new
    RSpec::Core::Runner.run(
      [test_file, '--format', 'RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter'],
      $stderr,
      output
    )
    
    # Parse the output
    output.rewind
    json_data = JSON.parse(output.read)
    
    # Check case-insensitive test
    case_test = json_data["examples"].find { |e| e["description"] == "matches with case-insensitive regex" }
    expect(case_test).not_to be_nil
    expect(case_test["status"]).to eq("failed")
    
    # Verify regex serialization
    expected_str = JSON.parse(case_test["details"]["expected"])
    expected_data = JSON.parse(expected_str)
    
    expect(expected_data).to eq({
      "_regexp_source" => "hello",
      "_regexp_options" => 1  # IGNORECASE flag
    })
    
    # Check multiline test
    multiline_test = json_data["examples"].find { |e| e["description"] == "matches with multiline regex" }
    expected_str = JSON.parse(multiline_test["details"]["expected"])
    expected_data = JSON.parse(expected_str)
    
    expect(expected_data).to eq({
      "_regexp_source" => "line1.line2",
      "_regexp_options" => 4  # MULTILINE flag
    })
    
    # Check include test with regex
    include_test = json_data["examples"].find { |e| e["description"] == "includes regex in array" }
    expected_str = JSON.parse(include_test["details"]["expected"])
    
    # For include matcher, the regex should be in the expecteds array
    expect(expected_str).to include("_regexp_source")
    
  ensure
    # Cleanup
    File.delete(test_file) if File.exist?(test_file)
  end
  
  it "handles regex serialization with Oj for nested structures" do
    # Test the serializer directly
    serializer = RSpec::EnrichedJson::ExpectationHelperWrapper::Serializer
    
    # Simple regex
    result = serializer.serialize_value(/test/i)
    expect(JSON.parse(result)).to eq({
      "_regexp_source" => "test",
      "_regexp_options" => 1
    })
    
    # Regex in array
    result = serializer.serialize_value([1, /pattern/, "test"])
    parsed = JSON.parse(result)
    
    # Oj will serialize the array, but our regex should be specially handled
    expect(result).to include("_regexp_source")
    expect(result).to include("pattern")
    
    # Regex in hash
    result = serializer.serialize_value({pattern: /\\d+/, name: "test"})
    expect(result).to include("_regexp_source")
    expect(result).to include("\\\\d+")
  end
end