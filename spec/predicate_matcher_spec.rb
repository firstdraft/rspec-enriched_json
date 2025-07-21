# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Predicate matcher value capture" do
  let(:formatter) { RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter.new(StringIO.new) }

  # Use the same Oj options for loading that we use for dumping
  let(:oj_load_options) do
    {
      mode: :object,        # Restore Ruby objects and symbols
      symbol_keys: true,    # Restore symbol keys
      auto_define: false,   # Safety: don't create arbitrary classes
      create_additions: false # Safety: don't use JSON additions
    }
  end

  context "BePredicate matchers" do
    it "captures true/false for be_empty matcher" do
      test_file = "spec/support/predicate_test.rb"
      File.write(test_file, <<~RUBY)
        RSpec.describe "Test" do
          it "checks empty array" do
            expect([]).to be_empty
          end
        end
      RUBY

      output = run_rspec(test_file)
      json = Oj.load(output)
      example = json["examples"].first

      expect(example["status"]).to eq("passed")
      # Values are JSON encoded in the output
      expect(Oj.load(example["details"]["expected"], oj_load_options)).to eq(true)
      expect(Oj.load(example["details"]["actual"], oj_load_options)).to eq(true)
      expect(example["details"]["matcher_name"]).to eq("RSpec::Matchers::BuiltIn::BePredicate")
    ensure
      File.delete(test_file) if File.exist?(test_file)
    end

    it "captures true/false for failing be_empty matcher" do
      test_file = "spec/support/predicate_test.rb"
      File.write(test_file, <<~RUBY)
        RSpec.describe "Test" do
          it "checks non-empty array" do
            expect([1, 2, 3]).to be_empty
          end
        end
      RUBY

      output = run_rspec(test_file)
      json = Oj.load(output)
      example = json["examples"].first

      expect(example["status"]).to eq("failed")
      expect(Oj.load(example["details"]["expected"], oj_load_options)).to eq(true)
      expect(Oj.load(example["details"]["actual"], oj_load_options)).to eq(false)
    ensure
      File.delete(test_file) if File.exist?(test_file)
    end

    it "captures false/false for negated be_empty matcher" do
      test_file = "spec/support/predicate_test.rb"
      File.write(test_file, <<~RUBY)
        RSpec.describe "Test" do
          it "checks non-empty array with negation" do
            expect([1, 2, 3]).not_to be_empty
          end
        end
      RUBY

      output = run_rspec(test_file)
      json = Oj.load(output)
      example = json["examples"].first

      expect(example["status"]).to eq("passed")
      expect(Oj.load(example["details"]["expected"], oj_load_options)).to eq(false)
      expect(Oj.load(example["details"]["actual"], oj_load_options)).to eq(false)
      expect(example["details"]["negated"]).to eq(true)
    ensure
      File.delete(test_file) if File.exist?(test_file)
    end
  end

  context "Has matchers" do
    it "captures true/true for have_key matcher" do
      test_file = "spec/support/predicate_test.rb"
      File.write(test_file, <<~RUBY)
        RSpec.describe "Test" do
          it "checks for existing key" do
            expect({a: 1}).to have_key(:a)
          end
        end
      RUBY

      output = run_rspec(test_file)
      json = Oj.load(output)
      example = json["examples"].first

      expect(example["status"]).to eq("passed")
      expect(Oj.load(example["details"]["expected"])).to eq(true)
      expect(Oj.load(example["details"]["actual"])).to eq(true)
      expect(example["details"]["matcher_name"]).to eq("RSpec::Matchers::BuiltIn::Has")
    ensure
      File.delete(test_file) if File.exist?(test_file)
    end

    it "captures true/false for failing have_key matcher" do
      test_file = "spec/support/predicate_test.rb"
      File.write(test_file, <<~RUBY)
        RSpec.describe "Test" do
          it "checks for missing key" do
            expect({a: 1}).to have_key(:b)
          end
        end
      RUBY

      output = run_rspec(test_file)
      json = Oj.load(output)
      example = json["examples"].first

      expect(example["status"]).to eq("failed")
      expect(Oj.load(example["details"]["expected"], oj_load_options)).to eq(true)
      expect(Oj.load(example["details"]["actual"], oj_load_options)).to eq(false)
    ensure
      File.delete(test_file) if File.exist?(test_file)
    end
  end

  private

  def run_rspec(test_file)
    output = nil
    Dir.mktmpdir do |dir|
      output_file = File.join(dir, "output.json")
      cmd = "bundle exec rspec #{test_file} --format RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter --out #{output_file} 2>&1"
      system(cmd, out: File::NULL)
      output = File.read(output_file)
    end
    output
  end
end
