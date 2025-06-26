# RSpec::EnrichedJson

A drop-in replacement for RSpec's built-in JSON formatter that enriches the output with structured failure data. This makes it easy to programmatically analyze test results, extract expected/actual values, and build better CI/CD integrations.

## Quick Demo

To see the difference between RSpec's built-in JSON formatter and this enriched formatter:

```bash
ruby demo.rb
```

This interactive demo script runs the same failing tests with both formatters and shows you the difference side-by-side. No external dependencies, no file cleanup needed!

**What you'll see:**
- **Built-in formatter**: Failure information embedded in string messages  
- **Enriched formatter**: Adds structured data with:
  - `expected`: The expected value as a proper JSON object
  - `actual`: The actual value as a proper JSON object  
  - `matcher_name`: The RSpec matcher class used
  - `original_message`: Preserved when custom messages are provided

## Requirements

- Ruby 2.7 or higher
- RSpec 3.0 or higher

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rspec-enriched_json'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install rspec-enriched_json

## Usage

Use it just like RSpec's built-in JSON formatter:

```bash
# Command line
rspec --format RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter

# Or in your .rspec file
--format RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter

# Or in spec_helper.rb
RSpec.configure do |config|
  config.formatter = RSpec::EnrichedJson::Formatters::EnrichedJsonFormatter
end
```

## What's Different?

### Standard RSpec JSON Output

With RSpec's built-in JSON formatter, failure information comes as a string:

```json
{
  "exception": {
    "message": "\nexpected: \"Hello, Ruby!\"\n     got: \"Hello, World!\"\n\n(compared using ==)\n"
  }
}
```

### Enriched JSON Output

With this gem, you get structured data alongside the original message:

```json
{
  "exception": {
    "class": "RSpec::EnrichedJson::EnrichedExpectationNotMetError",
    "message": "\nexpected: \"Hello, Ruby!\"\n     got: \"Hello, World!\"\n\n(compared using ==)\n",
    "backtrace": ["./spec/example_spec.rb:5:in `block (2 levels) in <top (required)>'"]
  },
  "details": {
    "expected": "Hello, Ruby!",
    "actual": "Hello, World!",
    "matcher_name": "RSpec::Matchers::BuiltIn::Eq",
    "original_message": null,
    "diff_info": {
      "diffable": true
    }
  }
}
```

## Features

- **Drop-in replacement**: Inherits from RSpec's JsonFormatter, maintaining 100% compatibility
- **Structured data extraction**: Expected and actual values as proper JSON objects
- **Rich object support**: Arrays, hashes, and custom objects are properly serialized
- **Original message preservation**: When you override with a custom message, the original is preserved
- **Graceful degradation**: Regular exceptions (non-expectation failures) work normally
- **Enhanced metadata capture**: Test location, tags, hierarchy, and custom metadata
- **Robust error recovery**: Handles objects that fail to serialize without crashing
- **Diff information**: Includes `diff_info.diffable` to help tools determine if values can be meaningfully diffed

## Examples

### Simple Values
```ruby
expect(1 + 1).to eq(3)
# details: { "expected": 3, "actual": 2 }
```

### Collections
```ruby
expect([1, 2, 3]).to eq([1, 2, 4])
# details: { "expected": [1, 2, 4], "actual": [1, 2, 3] }
```

### Complex Objects
```ruby
Product = Struct.new(:name, :price)
expect(Product.new("Laptop", 999)).to eq(Product.new("Laptop", 899))
# details includes class info and struct values
```

### Custom Messages
```ruby
expect(balance).to be >= required,
  "Insufficient funds: $#{balance} available, $#{required} required"
# exception.message: "Insufficient funds: $50 available, $100 required"
# details: { "original_message": "expected: >= 100\n     got:    50" }
```

### Metadata Capture
```ruby
it "validates user input", :slow, :db, priority: :high do
  expect(user).to be_valid
end
# metadata includes:
# - location: "./spec/models/user_spec.rb:42"
# - absolute_file_path: "/path/to/project/spec/models/user_spec.rb"
# - tags: { "slow": true, "db": true, "priority": "high" }
# - example_group_hierarchy: ["User", "validations", "email format"]
```

## Use Cases

- **CI/CD Integration**: Parse test results to create rich error reports
- **Test Analytics**: Track which values commonly cause test failures  
- **Debugging Tools**: Build tools that can display expected vs actual diffs
- **Learning Platforms**: Provide detailed feedback on why tests failed

## How It Works

The gem works by:

1. Patching RSpec's expectation system to capture structured data when expectations fail
2. Extending the JsonFormatter to include this data in the JSON output
3. Maintaining full backward compatibility with existing tools

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## Performance Considerations

The enriched formatter adds minimal overhead:
- Only processes failing tests (passing tests have no extra processing)
- Limits serialization depth to prevent infinite recursion
- Truncates large strings and collections to maintain reasonable output sizes
- No impact on test execution time, only on failure reporting

Default limits:
- Max serialization depth: 5 levels
- Max array size: 100 items
- Max hash size: 100 keys
- Max string length: 1000 characters

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/firstdraft/rspec-enriched_json.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
