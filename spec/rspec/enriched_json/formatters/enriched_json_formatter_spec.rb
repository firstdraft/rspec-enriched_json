# frozen_string_literal: true

require "spec_helper"

RSpec.describe RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter do
  it "inherits from RSpec's built-in JsonFormatter" do
    expect(described_class.superclass).to eq(RSpec::Core::Formatters::JsonFormatter)
  end

  it "responds to required formatter methods" do
    formatter = described_class.new(StringIO.new)
    expect(formatter).to respond_to(:stop)
    expect(formatter).to respond_to(:close)
  end
end
