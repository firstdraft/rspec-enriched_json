# frozen_string_literal: true

require "spec_helper"

RSpec.describe "diffable" do
  describe "diffable detection" do
    it "marks string comparisons as diffable" do
      test_content = <<~RUBY
        RSpec.describe "String diff" do
          it "compares strings" do
            expect("hello world").to eq("hello ruby")
          end
        end
      RUBY

      output = run_formatter_with_content(test_content)

      expect(output["examples"].first["details"]["diffable"]).to eq(true)
    end

    it "captures the unescaped string actual output" do
      test_content = <<~RUBY
        RSpec.describe "String diff" do
          it "compares strings" do
            expect("\\"Hello, ---world\\"").to match("Hello, world")
          end
        end
      RUBY

      output = run_formatter_with_content(test_content)
      details = output["examples"].first["details"]

      expect(details["expected"]).to eq("Hello, world")
      expect(details["actual"]).to eq("Hello, ---world")
    end

    it "marks array comparisons as diffable" do
      test_content = <<~RUBY
        RSpec.describe "Array diff" do
          it "compares arrays" do
            expect([1, 2, 3]).to eq([1, 2, 4])
          end
        end
      RUBY

      output = run_formatter_with_content(test_content)

      expect(output["examples"].first["details"]["diffable"]).to eq(true)
    end

    it "marks hash comparisons as diffable" do
      test_content = <<~RUBY
        RSpec.describe "Hash diff" do
          it "compares hashes" do
            expect({a: 1, b: 2}).to eq({a: 1, b: 3})
          end
        end
      RUBY

      output = run_formatter_with_content(test_content)

      expect(output["examples"].first["details"]["diffable"]).to eq(true)
    end

    it "marks different type comparisons as diffable when matcher says so" do
      test_content = <<~RUBY
        RSpec.describe "Type mismatch" do
          it "compares different types" do
            expect("string").to eq(123)
          end
        end
      RUBY

      output = run_formatter_with_content(test_content)

      # The Eq matcher considers itself diffable even for different types
      expect(output["examples"].first["details"]["diffable"]).to eq(true)
    end

    it "marks same class objects as diffable if they respond to to_s" do
      test_content = <<~RUBY
        class Person
          attr_reader :name
          def initialize(name)
            @name = name
          end
          def to_s
            @name
          end
        end

        RSpec.describe "Object diff" do
          it "compares objects" do
            expect(Person.new("Alice")).to eq(Person.new("Bob"))
          end
        end
      RUBY

      output = run_formatter_with_content(test_content)

      expect(output["examples"].first["details"]["diffable"]).to eq(true)
    end

    it "marks nil comparisons as diffable when matcher says so" do
      test_content = <<~RUBY
        RSpec.describe "Nil comparison" do
          it "compares with nil" do
            expect(nil).to eq("something")
          end
        end
      RUBY

      output = run_formatter_with_content(test_content)

      # The Eq matcher considers itself diffable even with nil values
      expect(output["examples"].first["details"]["diffable"]).to eq(true)
    end

    it "respects matcher's diffable? method if present" do
      test_content = <<~RUBY
        RSpec::Matchers.define :custom_matcher do
          match do |actual|
            false
          end

          def diffable?
            false
          end
        end

        RSpec.describe "Custom matcher" do
          it "uses custom diffable setting" do
            expect("hello").to custom_matcher
          end
        end
      RUBY

      output = run_formatter_with_content(test_content)

      expect(output["examples"].first["details"]["diffable"]).to eq(false)
    end

    it "uses our logic when matcher has no diffable? method" do
      test_content = <<~RUBY
        # Custom matcher without diffable? method
        class SimpleMatcher
          def matches?(actual)
            @actual = actual
            false
          end
          
          def failure_message
            "failed"
          end
          
          def expected
            nil
          end
          
          def actual
            @actual
          end
        end

        RSpec.describe "Matcher without diffable?" do
          it "nil comparison uses our logic" do
            expect("something").to SimpleMatcher.new
          end
        end
      RUBY

      output = run_formatter_with_content(test_content)

      # Our logic: nil vs string is not diffable
      expect(output["examples"].first["details"]["diffable"]).to eq(false)
    end
  end

  it "removes diff from the message if expected and actual are present" do
    test_content = <<~RUBY
      RSpec.describe "Account balance" do
        it "matches a sub-string" do
          expect("Your account balance is: -50").to match(/Your account balance is: [1-9]\d*/)
        end
      end
    RUBY

    output = run_formatter_with_content(test_content)
    message = output["examples"].first["exception"]["message"]

    expect(message).to include("expected \"Your account balance is: -50\"")
    expect(message).to include("to match /Your account balance is:")
    expect(message).not_to include("Diff:")
  end
end
