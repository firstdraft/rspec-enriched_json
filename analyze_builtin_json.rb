#!/usr/bin/env ruby
# Script to demonstrate how RSpec's built-in JSON formatter handles custom failure messages

require "tempfile"
require "json"

# Create a temporary test file
test_code = <<~RUBY
  RSpec.describe "Custom Message Test" do
    it "fails with custom message provided" do
      balance = 50
      required = 100
      expect(balance).to be >= required, "Insufficient funds: need \#{required} but only have \#{balance}"
    end

    it "fails without custom message" do
      expect(2).to eq(3)
    end
  end
RUBY

# Write to temp file
test_file = Tempfile.new(["test_", ".rb"])
test_file.write(test_code)
test_file.close

# Run RSpec with built-in JSON formatter
# Use system ruby to avoid bundler loading enriched_json
full_output = `/usr/bin/ruby -e "require 'rspec'; load '#{test_file.path}'; RSpec.configure {|c| c.formatter = 'json'}; RSpec::Core::Runner.run([])" 2>&1`

puts "Full output:"
puts full_output
puts "\n" + "=" * 50

# Extract just the JSON line (last line)
json_output = full_output.split("\n").last

puts "JSON line:"
puts json_output
puts "\n" + "=" * 50

# Parse and display the JSON
begin
  result = JSON.parse(json_output)

  puts "RSpec Built-in JSON Formatter Output Analysis:"
  puts "=" * 50

  result["examples"].each_with_index do |example, i|
    puts "\nExample #{i + 1}: #{example["description"]}"
    puts "Status: #{example["status"]}"

    if example["exception"]
      puts "Exception Class: #{example["exception"]["class"]}"
      puts "Exception Message:"
      puts example["exception"]["message"].split("\n").map { |line| "  #{line}" }.join("\n")
    end
  end

  puts "\n" + "=" * 50
  puts "\nKey Observation:"
  puts "Custom failure messages in RSpec are embedded within the exception message string,"
  puts "not as a separate field in the JSON output."
ensure
  test_file.unlink
end
