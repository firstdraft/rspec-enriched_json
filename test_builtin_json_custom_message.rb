require "rspec"

RSpec.describe "Built-in JSON Formatter Custom Message Test" do
  it "fails with a simple custom message" do
    balance = 50
    required = 100
    expect(balance).to be >= required, "Insufficient funds: need $#{required} but only have $#{balance}"
  end

  it "fails without custom message" do
    expect(1 + 1).to eq(3)
  end

  it "fails with hash expectation and custom message" do
    actual_response = {status: 200, body: "OK"}
    expected_response = {status: 404, body: "Not Found"}
    expect(actual_response).to eq(expected_response), "API returned wrong response"
  end
end
