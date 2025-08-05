# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Stdout matcher value capture" do
  let(:formatter) { RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter.new(StringIO.new) }

  # Use the same Oj options for loading that we use for dumping
  let(:oj_load_options) do
    {
      mode: :object,
      symbol_keys: true,
      auto_define: false,
      create_additions: false
    }
  end

  it "captures actual when spec passes" do
    test_file = "spec/support/stdout_passing_spec.rb"
    File.write(test_file, <<~RUBY)
      RSpec.describe "Test" do
        it "checks output" do
          expect { puts "Hello" }.to output("Hello\\n").to_stdout
        end
      end
    RUBY

    output = run_rspec(test_file)
    json = Oj.load(output)
    example = json["examples"].first

    expect(example["details"]["expected"]).to eq("\"Hello\\n\"")
    expect(example["details"]["actual"]).to eq("Hello\n")
  ensure
    File.delete(test_file) if File.exist?(test_file)
  end

  it "captures actual when spec fails" do
    test_file = "spec/support/stdout_passing_spec.rb"
    File.write(test_file, <<~RUBY)
      RSpec.describe "Test" do
        it "checks output" do
          expect { puts "Hello" }.to output("Bye\\n").to_stdout
        end
      end
    RUBY

    output = run_rspec(test_file)
    json = Oj.load(output)
    example = json["examples"].first

    expect(example["details"]["expected"]).to eq("\"Bye\\n\"")
    expect(example["details"]["actual"]).to eq("\"Hello\\n\"")
  ensure
    File.delete(test_file) if File.exist?(test_file)
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
