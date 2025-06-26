#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo script for RSpec::EnrichedJson
# Shows side-by-side comparison of built-in vs enriched JSON formatters
#
# Usage: ruby demo.rb

require "json"
require "tempfile"
require "pathname"

# Add lib to load path
lib_path = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)

puts "🔍 RSpec::EnrichedJson Demo"
puts "=" * 60
puts

# Create a simple test file for demo
test_content = <<~RUBY
  RSpec.describe "Demo Test" do
    it "fails with string comparison" do
      expect("Hello, World!").to eq("Hello, Ruby!")
    end
    
    it "fails with hash comparison" do
      actual = {name: "Alice", age: 30, city: "NYC"}
      expected = {name: "Alice", age: 25, city: "Boston"}
      expect(actual).to eq(expected)
    end
    
    it "fails with array comparison" do
      expect([1, 2, 3]).to contain_exactly(1, 2, 4)
    end

    it "fails with custom message" do
      balance = 50
      required = 100
      expect(balance).to be >= required, "Insufficient funds: need $\#{required}, have $\#{balance}"
    end
  end
RUBY

# Write test file
Tempfile.create(["demo_test", ".rb"]) do |test_file|
  test_file.write(test_content)
  test_file.flush

  puts "📊 Comparing JSON output for the same failing test:"
  puts

  # Collect outputs
  builtin_output = nil
  enriched_output = nil

  # Run with built-in JSON formatter
  Tempfile.create(["builtin_output", ".json"]) do |builtin_file|
    `bundle exec rspec #{test_file.path} --format json --out #{builtin_file.path} --format progress --out /dev/null 2>&1`
    builtin_output = JSON.parse(File.read(builtin_file.path))
  end

  # Run with enriched formatter
  Tempfile.create(["enriched_output", ".json"]) do |enriched_file|
    `bundle exec rspec #{test_file.path} --format RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter --out #{enriched_file.path} -r ./lib/rspec/enriched_json --format progress --out /dev/null 2>&1`
    enriched_output = JSON.parse(File.read(enriched_file.path))
  end

  # Show string comparison example
  puts "Example 1: String Comparison"
  puts "-" * 60

  builtin_example = builtin_output["examples"].find { |ex| ex["description"] == "fails with string comparison" }
  enriched_example = enriched_output["examples"].find { |ex| ex["description"] == "fails with string comparison" }

  puts "📄 Standard JSON formatter output:"
  puts JSON.pretty_generate({
    "description" => builtin_example["description"],
    "exception" => builtin_example["exception"]
  })

  puts
  puts "📦 Enriched JSON formatter output:"
  puts JSON.pretty_generate({
    "description" => enriched_example["description"],
    "exception" => enriched_example["exception"],
    "structured_data" => enriched_example["structured_data"]
  })

  puts
  puts "Example 2: Hash Comparison"
  puts "-" * 60

  builtin_example = builtin_output["examples"].find { |ex| ex["description"] == "fails with hash comparison" }
  enriched_example = enriched_output["examples"].find { |ex| ex["description"] == "fails with hash comparison" }

  puts "📄 Standard formatter: Expected/actual values buried in string message:"
  puts builtin_example["exception"]["message"].split("\n").map { |line| "  #{line}" }.join("\n")
  puts
  puts "📦 Enriched formatter: Expected/actual values as structured data:"
  puts "  expected: #{enriched_example["structured_data"]["expected"].inspect}"
  puts "  actual:   #{enriched_example["structured_data"]["actual"].inspect}"

  puts
  puts "Example 3: Custom Error Message"
  puts "-" * 60

  builtin_example = builtin_output["examples"].find { |ex| ex["description"] == "fails with custom message" }
  enriched_example = enriched_output["examples"].find { |ex| ex["description"] == "fails with custom message" }

  puts "📄 Standard formatter: Only shows custom message"
  puts "  Message: \"#{builtin_example["exception"]["message"].strip}\""
  puts "  (No access to expected/actual values)"
  puts
  puts "📦 Enriched formatter: Custom message PLUS structured data"
  puts "  Your message: \"#{enriched_example["exception"]["message"].strip}\""
  puts "  Original message preserved: \"#{enriched_example["structured_data"]["original_message"]}\""
  puts "  Still get structured data: expected=#{enriched_example["structured_data"]["expected"]}, actual=#{enriched_example["structured_data"]["actual"]}"
end

puts
puts "✨ Benefits:"
puts "• Parse test failures programmatically without regex"
puts "• Build better error reports with actual vs expected values"
puts "• Keep custom messages while preserving matcher details"
puts "• Works with ALL RSpec matchers automatically"
puts
puts "🚀 To use in your project:"
puts "  rspec --format RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter --out results.json"
puts
