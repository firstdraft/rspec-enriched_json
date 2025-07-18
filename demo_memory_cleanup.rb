#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "rspec/core"
require "rspec/enriched_json"

# Create a simple test file in memory
test_content = <<~RUBY
  RSpec.describe "Memory cleanup demo" do
    it "passes test 1" do
      expect(1).to eq(1)
    end
    
    it "passes test 2" do
      expect("hello").to eq("hello")
    end
    
    it "fails test 3" do
      expect(2 + 2).to eq(5)
    end
  end
RUBY

# Write test to a temp file
require "tempfile"
test_file = Tempfile.new(["memory_test", ".rb"])
test_file.write(test_content)
test_file.close

puts "Running tests..."
puts "Test values before suite: #{RSpec::EnrichedJson.all_test_values.size} entries"

# Configure RSpec to use our formatter
RSpec.configure do |config|
  config.formatter = RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter
  config.output_stream = StringIO.new  # Suppress output for demo
end

# Run the tests
RSpec::Core::Runner.run([test_file.path])

puts "\nTest values after individual tests ran: #{RSpec::EnrichedJson.all_test_values.size} entries"
puts "Keys captured: #{RSpec::EnrichedJson.all_test_values.keys}"

# The formatter's close method should clear values after outputting
puts "\nNote: Cleanup now happens in formatter's close method to preserve values for JSON output."
puts "In production, values are cleared after JSON is written, preventing memory leaks."

# Manually call clear to demonstrate it works
RSpec::EnrichedJson.clear_test_values
puts "\nAfter manual cleanup: #{RSpec::EnrichedJson.all_test_values.size} entries"

if RSpec::EnrichedJson.all_test_values.empty?
  puts "✅ Memory cleanup successful! Values can be cleared when needed."
else
  puts "❌ Memory cleanup failed! Test values still present."
end

# Cleanup
test_file.unlink
