# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Edge case handling" do
  it "handles circular references gracefully" do
    a = []
    a << a  # Circular reference

    begin
      expect(a).to eq([1, 2, 3])
    rescue RSpec::EnrichedJson::EnrichedExpectationNotMetError => e
      # Should not crash, should handle gracefully
      expect(e.details[:actual]).to be_a(Array)
    end
  end

  it "handles matchers without expected/actual methods" do
    # Some matchers might not have these methods

    expect { raise "error" }.not_to raise_error
  rescue RSpec::EnrichedJson::EnrichedExpectationNotMetError => e
    # Should handle gracefully with nil values
    expect(e.details[:expected]["class"]).to eq("NilClass")
    expect(e.details[:actual]["class"]).to eq("NilClass")
  end

  it "handles encoding issues" do
    invalid_utf8 = (+"\xFF\xFE").force_encoding("UTF-8")

    begin
      expect(invalid_utf8).to eq("valid string")
    rescue RSpec::EnrichedJson::EnrichedExpectationNotMetError => e
      # Should not crash on invalid encoding
      expect(e.details).to have_key(:actual)
    end
  end

  it "handles exceptions during serialization" do
    class BadObject # rubocop:disable Lint/ConstantDefinitionInBlock
      def inspect
        raise "Cannot inspect!"
      end

      def to_s
        raise "Cannot convert to string!"
      end
    end

    begin
      expect(BadObject.new).to eq("something")
    rescue => e  # Catch any exception, not just our enriched one
      # The error happens during RSpec's message generation, before our code runs
      # This is actually a limitation - if inspect fails, RSpec itself will fail
      expect(e.class).to eq(RuntimeError)
      expect(e.message).to eq("Cannot inspect!")
    end
  end

  context "handling Ruby literals" do
    it "serializes nil" do
      expect("Alice").to eq(nil)
    rescue RSpec::EnrichedJson::EnrichedExpectationNotMetError => e
      # Should not crash on invalid encoding
      expect(e.details[:expected]["class"]).to eq("NilClass")
      expect(e.details[:expected]["inspect"]).to eq("nil")
      expect(e.details[:expected]["to_s"]).to eq("")
    end

    it "serializes symbols" do
      expect(:name).to eq(:age)
    rescue RSpec::EnrichedJson::EnrichedExpectationNotMetError => e
      # Should not crash on invalid encoding
      expect(e.details[:expected]["class"]).to eq("Symbol")
      expect(e.details[:expected]["inspect"]).to eq(":age")
      expect(e.details[:expected]["to_s"]).to eq("age")
    end
  end
end
