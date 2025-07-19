# frozen_string_literal: true

require "spec_helper"

RSpec.describe RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter do
  it "inherits from RSpec's built-in JsonFormatter" do
    expect(described_class.superclass).to eq(RSpec::Core::Formatters::JsonFormatter)
  end
end
