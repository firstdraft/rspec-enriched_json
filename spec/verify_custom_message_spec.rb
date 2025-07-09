# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Custom message behavior verification" do
  it "preserves custom messages in the original location" do
    # When a custom message is provided, RSpec replaces the entire failure message
    # We need to ensure our enriched formatter doesn't change this behavior

    balance = 50
    required = 100

    begin
      expect(balance).to be >= required, "Insufficient funds"
    rescue RSpec::EnrichedJson::EnrichedExpectationNotMetError => e
      # The exception message should be the custom message
      expect(e.message).to eq("Insufficient funds")

      # But we also preserve the original message that was overridden
      expect(e.details[:original_message]).to include("expected: >= 100")
      expect(e.details[:original_message]).to include("got:")
    end
  end

  it "shows default message when no custom message provided" do
    balance = 50
    required = 100

    begin
      expect(balance).to be >= required
    rescue RSpec::EnrichedJson::EnrichedExpectationNotMetError => e
      # The exception message should be the default matcher message
      expect(e.message).to include("expected: >= 100")
      expect(e.message).to include("got:    50")

      # No original message needed since we're using the default
      expect(e.details[:original_message]).to be_nil
    end
  end

  it "removes diff from the custom message if expected and actual are present" do
    expect("Your account balance is: -50").to match(/Your account balance is: [1-9]\d*/), "Insufficient funds"
  rescue RSpec::EnrichedJson::EnrichedExpectationNotMetError => e
    # The exception message should be the custom message
    expect(e.message).to eq("Insufficient funds")

    # But we also preserve the original message that was overridden
    expect(e.details[:original_message]).to include("expected \"Your account balance is: -50\"")
    expect(e.details[:original_message]).to include("to match /Your account balance is:")
  end
end
