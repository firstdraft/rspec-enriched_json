# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Special serialization cases" do
  describe "stdout actual detection" do
    it "marks string comparisons as diffable" do
      test_content = <<~RUBY
        RSpec.describe "stdout" do
          it "compares strings" do
            expect { require_relative("#{Dir.pwd}/spec/support/code.rb") }.to output(/Hello, world!/).to_stdout
          end
        end
      RUBY

      p output = run_formatter_with_content(test_content)

      puts "====" * 3
      p output["examples"].first["details"]["actual"]
      p output["examples"].first["details"]["expected"]
      puts "====" * 3
      puts "\n\n\n" * 3
      expect(output["examples"].first["details"]["actual"]).to match("Hello, World!")
    end
  end
end