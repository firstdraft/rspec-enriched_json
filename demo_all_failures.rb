#!/usr/bin/env ruby

# Comprehensive demo of RSpec failure types and JSON formatters
#
# To use this demo:
#   1. Run with built-in JSON formatter:
#      bundle exec rspec demo_all_failures.rb --format json --no-profile 2>/dev/null | jq .
#
#   2. Run with enriched JSON formatter:
#      bundle exec rspec demo_all_failures.rb --format RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter --no-profile -r ./lib/rspec/enriched_json 2>/dev/null | jq .

RSpec.describe "All Types of Test Failures" do
  # This will cause an error outside of examples
  # Uncomment the next line to see how formatters handle it:
  # undefined_method_call

  # Or try this safer version that allows tests to still run:
  begin
    # Simulate code that might run at describe level
    nil.some_undefined_method
  rescue => e
    warn "Error outside example: #{e.class} - #{e.message}"
  end

  describe "Basic equality failures" do
    it "fails with simple equality" do
      expect(1 + 1).to eq(3)
    end

    it "fails with string comparison" do
      actual = "Hello, World!"
      expected = "Hello, Ruby!"
      expect(actual).to eq(expected)
    end

    it "fails with array comparison" do
      expect([1, 2, 3]).to eq([1, 2, 4])
    end

    it "fails with hash comparison" do
      actual = {name: "Alice", age: 30}
      expected = {name: "Alice", age: 25}
      expect(actual).to eq(expected)
    end

    it "fails with custom message" do
      user_balance = 50
      required_amount = 100
      expect(user_balance).to be >= required_amount,
        "Insufficient funds: user has $#{user_balance} but needs $#{required_amount}"
    end
  end

  describe "Predicate matchers" do
    it "fails with be_nil" do
      expect("not nil").to be_nil
    end

    it "fails with be_empty" do
      expect([1, 2, 3]).to be_empty
    end

    it "fails with be_truthy" do
      expect(false).to be_truthy
    end

    it "fails with be_falsey" do
      expect(true).to be_falsey
    end

    it "fails with have_key" do
      expect({a: 1, b: 2}).to have_key(:c)
    end

    it "fails with exist (file system)" do
      expect("/non/existent/file.txt").to exist
    end
  end

  describe "Comparison matchers" do
    it "fails with be >" do
      expect(5).to be > 10
    end

    it "fails with be <" do
      expect(10).to be < 5
    end

    it "fails with be <=" do
      expect(10).to be <= 5
    end

    it "fails with be_between" do
      expect(15).to be_between(1, 10)
    end

    it "fails with be_within" do
      expect(Math::PI).to be_within(0.001).of(3.0)
    end
  end

  describe "Type and class matchers" do
    it "fails with be_a" do
      expect("string").to be_a(Integer)
    end

    it "fails with be_an_instance_of" do
      expect([]).to be_an_instance_of(Hash)
    end

    it "fails with be_kind_of" do
      expect(5).to be_kind_of(String)
    end
  end

  describe "String and array matchers" do
    it "fails with start_with" do
      expect("Hello World").to start_with("Goodbye")
    end

    it "fails with end_with" do
      expect("Hello World").to end_with("Ruby")
    end

    it "fails with include" do
      expect("Hello World").to include("Ruby")
    end

    it "fails with match regex" do
      expect("user@example.com").to match(/^admin@/)
    end

    it "fails with contain_exactly" do
      expect([1, 2, 3]).to contain_exactly(3, 2, 1, 4)
    end
  end

  describe "Exception matchers" do
    it "fails with unexpected exception" do
      def divide(a, b)
        a / b
      end

      divide(10, 0) # Will raise ZeroDivisionError
    end

    it "fails due to missing method before assertion" do
      class Person # standard:disable Lint/ConstantDefinitionInBlock
        attr_reader :name

        def initialize(name, age)
          @name = name
          @age = age
        end
      end

      person = Person.new("Bob", 30)
      person.age = 31  # This will fail with NoMethodError
      expect(person.age).to eq(31)  # Never reaches this assertion
    end

    it "fails when expecting wrong exception type" do
      expect { "not a number" + 5 }.to raise_error(ArgumentError)
    end

    it "fails when expecting exception but none raised" do
      expect { 1 + 1 }.to raise_error(StandardError)
    end

    it "fails with exception message mismatch" do
      expect { raise "Wrong message" }.to raise_error("Different message")
    end
  end

  describe "Collection matchers" do
    it "fails with have_attributes" do
      User = Struct.new(:name, :email) # standard:disable Lint/ConstantDefinitionInBlock
      user = User.new("John", "john@example.com")
      expect(user).to have_attributes(name: "Jane", email: "jane@example.com")
    end

    it "fails with all matcher" do
      numbers = [2, 4, 5, 8]
      expect(numbers).to all(be_even)
    end

    it "fails with respond_to" do
      expect("string").to respond_to(:undefined_method)
    end

    it "fails with respond_to with arguments" do
      expect([]).to respond_to(:push).with(2).arguments
    end
  end

  describe "Change matchers" do
    it "fails when expecting change but none occurs" do
      counter = 5
      expect { counter + 1 }.to change { counter }.from(5).to(6)
    end

    it "fails with wrong change amount" do
      array = [1, 2, 3]
      expect { array.push(4) }.to change { array.size }.by(2)
    end

    it "fails with change by at_least" do
      score = 10
      expect { score += 1 }.to change { score }.by_at_least(5)
    end

    it "fails with change by at_most" do
      items = []
      expect { 3.times { items << "x" } }.to change { items.count }.by_at_most(2)
    end
  end

  describe "Output matchers" do
    it "fails with output to stdout" do
      expect { print "hello" }.to output("goodbye").to_stdout
    end

    it "fails with output to stderr" do
      expect { warn "warning" }.to output("error").to_stderr
    end

    it "fails with output regex" do
      expect { puts "User: John" }.to output(/Admin:/).to_stdout
    end
  end

  describe "Negated matchers" do
    it "fails with not_to eq" do
      expect(5).not_to eq(5)
    end

    it "fails with not_to be_nil" do
      expect(nil).not_to be_nil
    end

    it "fails with not_to include" do
      expect([1, 2, 3]).not_to include(2)
    end
  end

  describe "Compound matchers" do
    it "fails with and matcher" do
      expect(7).to be_odd.and be > 10
    end

    it "fails with or matcher where both fail" do
      expect(4).to be_odd.or be > 10
    end

    it "fails with complex compound" do
      expect("hello").to start_with("hi").and end_with("bye")
    end
  end

  describe "Satisfy matcher" do
    it "fails with custom block" do
      expect(10).to satisfy("be a multiple of 3") { |n| n % 3 == 0 }
    end

    it "fails with complex satisfaction" do
      expect("test@example").to satisfy("be a valid email") do |email|
        email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      end
    end
  end

  describe "Cover matcher" do
    it "fails with range coverage" do
      expect(1..10).to cover(15)
    end

    it "fails with multiple values" do
      expect(1..10).to cover(5, 15, 20)
    end
  end

  describe "Complex object failures" do
    class Product # standard:disable Lint/ConstantDefinitionInBlock
      attr_reader :name, :price, :stock

      def initialize(name, price, stock)
        @name = name
        @price = price
        @stock = stock
      end

      def in_stock?
        @stock > 0
      end
    end

    it "fails with custom object comparison" do
      product1 = Product.new("Laptop", 999.99, 5)
      product2 = Product.new("Laptop", 899.99, 5)
      expect(product1).to eq(product2)
    end

    it "fails with deeply nested structures" do
      actual = {
        user: {
          name: "John",
          address: {
            city: "New York",
            coords: {lat: 40.7128, lng: -74.0060}
          }
        }
      }
      expected = actual.deep_dup
      expected[:user][:address][:city] = "Boston"
      expect(actual).to eq(expected)
    end
  end

  describe "Array-specific matchers" do
    it "fails with match_array (order independent)" do
      expect([1, 2, 3]).to match_array([1, 2, 3, 4])
    end

    it "fails when array contains specific pattern" do
      expect([{id: 1}, {id: 2}, {id: 3}]).to include(
        a_hash_including(id: 4)
      )
    end
  end

  describe "Hash matchers" do
    it "fails with include hash" do
      expect({a: 1, b: 2}).to include(c: 3)
    end

    it "fails with hash including" do
      user = {name: "John", age: 30, city: "NYC"}
      expect(user).to match(a_hash_including(name: "Jane", age: 30))
    end
  end

  describe "Fuzzy matchers" do
    it "fails with a_string_matching" do
      expect("Hello World").to eq(a_string_matching(/Goodbye/))
    end

    it "fails with a_value_within" do
      expect(10.5).to eq(a_value_within(0.1).of(11.0))
    end

    it "fails with a_collection_containing_exactly" do
      expect([1, 2, 3]).to match(a_collection_containing_exactly(1, 2, 3, 4))
    end
  end
end
