# TODOs for RSpec::EnrichedJson

## Completed Features

- [x] **Structured Data Extraction**
  - Expected and actual values are captured as proper JSON objects (not strings)
  - Works with all RSpec matchers through universal wrapper approach
  - Graceful degradation for matchers without expected/actual methods

- [x] **Matcher Name Capture**
  - Full matcher class name included (e.g., "RSpec::Matchers::BuiltIn::Eq")
  - Available for all matchers that fail

- [x] **Rich Object Serialization**
  - Arrays and hashes properly serialized with safety limits
  - Custom objects include class name, instance variables, and string representations
  - Special handling for Structs with `struct_values` field
  - Performance limits: max depth (5), max array/hash size (100), max string length (1000)

- [x] **Original Message Preservation**
  - When custom failure messages are provided, original matcher message is preserved
  - Available in `original_message` field of structured data

## High Priority Improvements

- [ ] **Add Configuration Options**
  - Allow customization of serialization limits (max_depth, max_array_size, max_string_length)
  - Toggle inclusion of metadata, timestamps, backtrace
  - Provide sensible defaults with ability to override
  ```ruby
  RSpec::EnrichedJson.configure do |config|
    config.max_depth = 10
    config.max_string_length = 5000
    config.include_metadata = true
    config.include_timestamps = true
  end
  ```

- [ ] **Support Aggregate Failures**
  - Capture all failures in aggregate_failures blocks, not just the first
  - Structure output to include array of failures
  - Critical for modern test suites using aggregate_failures

- [ ] **Add Metadata Capture**
  - File path and line numbers
  - Custom tags (`:focus`, `:slow`, `:db`, `:priority`, etc.)
  - Example group hierarchy
  - Test IDs for re-running specific tests
  - Described class information

- [ ] **Smart ActiveRecord/ActiveModel Handling**
  - Special serialization for Rails models
  - Extract attributes instead of just inspect string
  - Handle associations intelligently
  - Avoid N+1 serialization issues

## Medium Priority Improvements

- [ ] **Better Error Recovery**
  - Graceful handling when inspect/to_s raises errors
  - Provide helpful context about serialization failures
  - Include fallback values and error reasons
  ```ruby
  {
    "serialization_error": true,
    "reason": "Circular reference detected",
    "class": "User",
    "fallback_value": "#<User id: 123>"
  }
  ```

- [ ] **Thread Safety**
  - Ensure wrapper works correctly with parallel test execution
  - Test with parallel_tests gem
  - Document thread safety guarantees

- [ ] **Performance Monitoring**
  - Optional capture of started_at/finished_at timestamps
  - Memory usage tracking (if enabled)
  - Performance impact documentation

- [ ] **Smart Serialization Improvements**
  - Better handling of Date/Time objects (ISO8601 format)
  - Support for custom serializers per class
  - Handle binary data gracefully
  - Deal with mixed encoding issues

- [ ] **Multiple Output Formats**
  - Minimal format for CI (essential data only)
  - Full format for debugging (all available data)
  - Allow format selection via command line

## Low Priority Improvements

- [ ] **Integration Helpers**
  - CI/CD annotation generators (GitHub, GitLab, etc.)
  - HTML/Markdown report generators
  - Example parsers in multiple languages

- [ ] **Better Installation Experience**
  - Auto-configuration helper
  - CLI shortcuts (`--format enriched`)
  - Migration guide from other formatters

- [ ] **Enhanced Documentation**
  - Comprehensive CI/CD integration guide
  - Performance benchmarks vs vanilla formatter
  - Troubleshooting guide for common issues
  - Example JSON parsing in Ruby, Python, JavaScript

- [ ] **Streaming Support**
  - For very large test suites
  - Reduce memory usage
  - Progressive output

## Nice to Have Features

- [ ] **SimpleCov Integration**
  - Include coverage data in output
  - Link failures to uncovered code

- [ ] **Spring/Zeus Compatibility**
  - Test and ensure compatibility
  - Document any special configuration needed

- [ ] **RSpec Bisect Support**
  - Ensure formatter works with RSpec's bisect command
  - Add bisect-specific data if helpful

- [ ] **Custom Matcher Support Guide**
  - Documentation for making custom matchers work well with enriched output
  - Best practices for expected/actual methods

## Technical Debt

- [ ] **Add More Integration Tests**
  - Test with various RSpec configurations
  - Test with popular RSpec extensions
  - Test with different Ruby versions

- [ ] **Performance Optimization**
  - Profile serialization code
  - Add caching where appropriate
  - Benchmark against vanilla formatter

- [ ] **Code Organization**
  - Consider splitting large files
  - Extract serialization strategies
  - Improve module structure

## Backward Compatibility

- [ ] **Version Output Format**
  - Add version field to JSON output
  - Plan for future breaking changes
  - Document upgrade paths

- [ ] **Maintain Compatibility**
  - All new fields should be opt-in
  - Existing structure must remain unchanged
  - Deprecation strategy for future changes