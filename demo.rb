#!/usr/bin/env ruby
# frozen_string_literal: true

# Demo script for RSpec::EnrichedJson
# Shows comprehensive examples of enriched JSON output for various matcher types
#
# Usage: ruby demo.rb

require "json"
require "tempfile"

# Add lib to load path
lib_path = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)

puts "RSpec::EnrichedJson - Comprehensive Matcher Output Examples"
puts "=" * 60
puts

# Create comprehensive test file
test_content = <<~'RUBY'
  RSpec.describe "Enriched JSON Output Examples" do
    # Basic Equality Matchers
    it "eq with strings" do
      expect("Hello, World!").to eq("Hello, Ruby!")
    end
    
    it "eq with numbers" do
      expect(42).to eq(100)
    end
    
    it "eq with arrays" do
      expect([1, 2, 3]).to eq([1, 2, 4])
    end
    
    it "eq with hashes" do
      expect({name: "Alice", age: 30}).to eq({name: "Alice", age: 25})
    end
    
    it "eq with nested structures" do
      actual = {
        user: {
          name: "John",
          address: {city: "NYC", zip: 10001}
        }
      }
      expected = {
        user: {
          name: "John", 
          address: {city: "Boston", zip: 02101}
        }
      }
      expect(actual).to eq(expected)
    end
    
    # Identity Matchers
    it "be (object identity)" do
      a = "test"
      b = "test"
      expect(a).to be(b)
    end
    
    it "equal (alias for be)" do
      expect([1, 2]).to equal([1, 2])
    end
    
    # Comparison Matchers
    it "be >" do
      expect(5).to be > 10
    end
    
    it "be <" do
      expect(100).to be < 50
    end
    
    it "be >=" do
      expect(5).to be >= 10
    end
    
    it "be <=" do
      expect(100).to be <= 50
    end
    
    it "be_between" do
      expect(15).to be_between(1, 10).exclusive
    end
    
    it "be_within" do
      expect(5.5).to be_within(0.1).of(6.0)
    end
    
    # Type Matchers
    it "be_a / be_kind_of" do
      expect("string").to be_a(Integer)
    end
    
    it "be_an_instance_of" do
      expect([]).to be_an_instance_of(Hash)
    end
    
    # Truthiness Matchers
    it "be_truthy" do
      expect(false).to be_truthy
    end
    
    it "be_falsey / be_falsy" do
      expect(true).to be_falsey
    end
    
    it "be_nil" do
      expect("not nil").to be_nil
    end
    
    # Predicate Matchers
    it "be_empty" do
      expect([1, 2, 3]).to be_empty
    end
    
    it "have_key" do
      expect({a: 1, b: 2}).to have_key(:c)
    end
    
    # Collection Matchers
    it "include" do
      expect([1, 2, 3]).to include(4)
    end
    
    it "include with multiple items" do
      expect([1, 2, 3]).to include(2, 4, 6)
    end
    
    it "include with hash" do
      expect({a: 1, b: 2}).to include(c: 3)
    end
    
    it "start_with" do
      expect("Hello World").to start_with("Goodbye")
    end
    
    it "end_with" do
      expect("Hello World").to end_with("Universe")
    end
    
    it "match (regex)" do
      expect("user@example.com").to match(/admin@/)
    end
    
    it "contain_exactly" do
      expect([1, 2, 3]).to contain_exactly(1, 2, 4)
    end
    
    it "match_array" do
      expect([1, 2, 3]).to match_array([1, 2, 3, 4])
    end
    
    it "all" do
      expect([1, 3, 5, 6]).to all(be_odd)
    end
    
    # String Matchers
    it "match with string" do
      expect("Hello").to match("Goodbye")
    end
    
    # Change Matchers
    it "change" do
      x = 5
      expect { x += 1 }.to change { x }.from(5).to(7)
    end
    
    it "change by" do
      arr = [1, 2]
      expect { arr.push(3) }.to change { arr.size }.by(2)
    end
    
    # Output Matchers
    it "output to stdout" do
      expect { print "hello" }.to output("goodbye").to_stdout
    end
    
    it "output to stderr" do
      expect { warn "warning" }.to output("error").to_stderr
    end
    
    # Exception Matchers
    it "raise_error" do
      expect { "not a number" + 5 }.to raise_error(ArgumentError)
    end
    
    it "raise_error with message" do
      expect { raise "boom" }.to raise_error("different message")
    end
    
    it "raise_error when none raised" do
      expect { 1 + 1 }.to raise_error
    end
    
    # Throw Matchers
    it "throw_symbol" do
      expect { throw :done }.to throw_symbol(:finished)
    end
    
    # Exist Matcher
    it "exist" do
      expect("/nonexistent/path").to exist
    end
    
    # Cover Matcher
    it "cover" do
      expect(1..10).to cover(15)
    end
    
    it "cover multiple values" do
      expect(1..10).to cover(5, 15)
    end
    
    # Respond To Matchers
    it "respond_to" do
      expect("string").to respond_to(:undefined_method)
    end
    
    it "respond_to with arguments" do
      expect([]).to respond_to(:push).with(2).arguments
    end
    
    # Have Attributes Matcher
    it "have_attributes" do
      Person = Struct.new(:name, :age)
      person = Person.new("John", 30)
      expect(person).to have_attributes(name: "Jane", age: 25)
    end
    
    # Satisfy Matcher
    it "satisfy" do
      expect(10).to satisfy("be even") { |n| n.odd? }
    end
    
    it "satisfy with complex block" do
      expect("test@invalid").to satisfy("be valid email") do |email|
        email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      end
    end
    
    # Compound Matchers
    it "and" do
      expect(7).to be_odd.and be > 10
    end
    
    it "or" do
      expect(4).to be_odd.or be > 10
    end
    
    # Negated Matchers
    it "not_to eq" do
      expect(5).not_to eq(5)
    end
    
    it "not_to include" do
      expect([1, 2, 3]).not_to include(2)
    end
    
    # Custom Messages
    it "custom failure message" do
      balance = 50
      required = 100
      expect(balance).to be >= required, "Insufficient funds: $#{balance} available, $#{required} required"
    end
    
    it "custom message with block" do
      expect(2 + 2).to eq(5) do
        "Math is broken! 2 + 2 should equal 5"
      end
    end
    
    # Complex Object Examples
    it "struct comparison" do
      Product = Struct.new(:name, :price)
      expect(Product.new("Laptop", 999)).to eq(Product.new("Laptop", 899))
    end
    
    # Metadata Examples
    it "test with metadata", :slow, :db, priority: :high do
      expect(true).to eq(false)
    end
    
    it "custom object with many instance variables" do
      class ComplexObject
        def initialize
          @a, @b, @c, @d, @e = 1, 2, 3, 4, 5
          @f, @g, @h, @i, @j = 6, 7, 8, 9, 10
        end
      end
      
      expect(ComplexObject.new).to eq("different object")
    end
    
    # Fuzzy Matchers
    it "a_string_matching" do
      expect({message: "Hello World"}).to include(message: a_string_matching(/Goodbye/))
    end
    
    it "a_hash_including" do
      expect({a: 1, b: 2, c: 3}).to match(a_hash_including(d: 4))
    end
    
    it "a_collection_containing_exactly" do
      expect([1, 2, 3]).to match(a_collection_containing_exactly(1, 2, 4))
    end
    
    it "an_instance_of" do
      expect([1, "two", :three]).to include(an_instance_of(Hash))
    end
    
    # Array Matchers with Complex Conditions
    it "include with hash conditions" do
      users = [{id: 1, name: "John"}, {id: 2, name: "Jane"}]
      expect(users).to include(a_hash_including(id: 3))
    end
    
    # Yield Matchers
    it "yield_control" do
      expect { |b| "not yielding".each(&b) }.to yield_control
    end
    
    it "yield_with_args" do
      expect { |b| [1, 2, 3].each(&b) }.to yield_with_args(4, 5)
    end
  end
RUBY

# Write and run test file
Tempfile.create(["demo_test", ".rb"]) do |test_file|
  test_file.write(test_content)
  test_file.flush

  # Run with enriched formatter only
  Tempfile.create(["enriched_output", ".json"]) do |output_file|
    `bundle exec rspec #{test_file.path} --format RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter --out #{output_file.path} -r ./lib/rspec/enriched_json --format progress --out /dev/null 2>&1`

    output = JSON.parse(File.read(output_file.path))
    examples = output["examples"].select { |ex| ex["status"] == "failed" }

    # Group examples by category for better organization
    categories = {
      "Basic Equality Matchers" => ["eq with strings", "eq with numbers", "eq with arrays", "eq with hashes", "eq with nested structures"],
      "Identity Matchers" => ["be (object identity)", "equal (alias for be)"],
      "Comparison Matchers" => ["be >", "be <", "be >=", "be <=", "be_between", "be_within"],
      "Type Matchers" => ["be_a / be_kind_of", "be_an_instance_of"],
      "Truthiness Matchers" => ["be_truthy", "be_falsey / be_falsy", "be_nil"],
      "Predicate Matchers" => ["be_empty", "have_key"],
      "Collection Matchers" => ["include", "include with multiple items", "include with hash", "start_with", "end_with", "match (regex)", "contain_exactly", "match_array", "all"],
      "String Matchers" => ["match with string"],
      "Change Matchers" => ["change", "change by"],
      "Output Matchers" => ["output to stdout", "output to stderr"],
      "Exception Matchers" => ["raise_error", "raise_error with message", "raise_error when none raised"],
      "Other Matchers" => ["throw_symbol", "exist", "cover", "cover multiple values", "respond_to", "respond_to with arguments", "have_attributes", "satisfy", "satisfy with complex block"],
      "Compound & Negated" => ["and", "or", "not_to eq", "not_to include"],
      "Custom Messages" => ["custom failure message", "custom message with block"],
      "Complex Objects" => ["struct comparison", "test with metadata", "custom object with many instance variables"],
      "Fuzzy Matchers" => ["a_string_matching", "a_hash_including", "a_collection_containing_exactly", "an_instance_of", "include with hash conditions"],
      "Yield Matchers" => ["yield_control", "yield_with_args"]
    }

    categories.each do |category, descriptions|
      category_examples = examples.select { |ex| descriptions.include?(ex["description"]) }
      next if category_examples.empty?

      puts "\n#{category}"
      puts "-" * category.length

      category_examples.each do |example|
        puts "\n### #{example["description"]}"
        puts JSON.pretty_generate({
          "exception" => {
            "class" => example["exception"]["class"],
            "message" => example["exception"]["message"]
          },
          "details" => example["details"]
        })
      end
    end
  end
end

puts "\n\nNote: This demonstrates the enriched JSON output for failing tests."
puts "The 'details' field provides programmatic access to expected/actual values."
