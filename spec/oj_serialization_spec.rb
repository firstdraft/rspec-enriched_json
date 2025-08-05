# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Special serialization cases" do
  let(:serializer) { RSpec::EnrichedJson::ExpectationHelperWrapper::Serializer }

  describe "Regexp serialization (our special case)" do
    it "serializes simple regex as inspect string" do
      result = JSON.parse(serializer.serialize_value(/hello/))
      expect(result).to eq("/hello/")
    end

    it "serializes regex with case-insensitive flag" do
      result = JSON.parse(serializer.serialize_value(/hello/i))
      expect(result).to eq("/hello/i")
    end

    it "serializes regex with multiline flag" do
      result = JSON.parse(serializer.serialize_value(/hello/m))
      expect(result).to eq("/hello/m")
    end

    it "serializes regex with extended flag" do
      result = JSON.parse(serializer.serialize_value(/hello/x))
      expect(result).to eq("/hello/x")
    end

    it "serializes regex with multiple flags in alphabetical order" do
      result = JSON.parse(serializer.serialize_value(/hello/imx))
      # Ruby's inspect method shows flags in a specific order: mix
      expect(result).to eq("/hello/mix")
    end

    it "serializes regex with special characters" do
      result = JSON.parse(serializer.serialize_value(/[a-z]+\s*\d{2,}/))
      expect(result).to eq("/[a-z]+\\s*\\d{2,}/")
    end

    it "serializes regex with escaped forward slashes" do
      result = JSON.parse(serializer.serialize_value(/http:\/\/example\.com/))
      expect(result).to eq("/http:\\/\\/example\\.com/")
    end
  end

  describe "serialization of Proc objects" do
    it "calls a simple Proc" do
      helloworld = proc { "Hello, world!" }
      result = serializer.serialize_value(helloworld)
      expect(result).to eq("Hello, world!")
    end
  end

  describe "Fallback behavior for errors" do
    it "uses fallback format when Oj.dump fails" do
      # Create an object that we'll mock to fail
      obj = Object.new

      # Mock Oj.dump to fail for this specific object
      allow(Oj).to receive(:dump).and_call_original
      allow(Oj).to receive(:dump).with(obj, anything).and_raise("Serialization failed")

      result = JSON.parse(serializer.serialize_value(obj))
      expect(result).to be_a(Hash)
      expect(result["_serialization_error"]).to eq("Serialization failed")
      expect(result["_class"]).to match(/Object/)
      expect(result["_to_s"]).to match(/#<Object:/)
    end
  end
end
