# frozen_string_literal: true

RSpec.describe "Regex matcher" do
  it "matches with regex" do
    expect("HELLO WORLD").to match(/hello/i)
  end
end
