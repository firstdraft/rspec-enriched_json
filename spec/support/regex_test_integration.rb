RSpec.describe "Regex tests" do
  it "matches with case-insensitive regex" do
    expect("HELLO").to match(/hello/i)
  end

  it "matches with multiline regex" do
    expect("line1\nline2").to match(/line1.line2/m)
  end

  it "includes regex in array" do
    expect(["test", "hello"]).to include(/world/)
  end
end
