# TODOs for Enhanced RSpec JSON Formatter

## Completed Features

These features have already been implemented in the current version:

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

## Potential Enhancements to Add

### High Priority - Most Valuable Additions

- [ ] **Custom Metadata/Tags**
  - Add all user-defined metadata to JSON output
  - Include tags like `:priority`, `:severity`, `:type`, `:db`, etc.
  - Useful for filtering, categorizing, and analyzing failures

- [ ] **Timing Timestamps**
  - Add `started_at` and `finished_at` timestamps (not just duration)
  - Useful for correlating with logs, metrics, and other system events
  - Help identify when failures occurred in long test suites

- [ ] **Aggregate Failures**
  - Show all failures in an example, not just the first
  - Include expected/actual for each failed expectation
  - Critical for examples using `:aggregate_failures`

- [ ] **Additional Matcher Details**
  - Add matcher-specific data (what was missing from arrays, ranges tested, etc.)
  - Show whether matcher supports diffing (`diffable?` status)
  - Include matcher configuration (e.g., case sensitivity for string matchers)

### Medium Priority - Useful Context

- [ ] **Multiple Location Formats**
  - Add `absolute_file_path` for IDE integration
  - Include `rerun_file_path` for easy test re-execution
  - Add `id` and `scoped_id` for precise test identification

- [ ] **Pending/Skip Details**
  - Include skip reasons
  - Show `pending_fixed` status
  - Add `pending_exception` details

- [ ] **Example Group Hierarchy**
  - Include parent group descriptions
  - Show full ancestry chain
  - Add shared example inclusion details

- [ ] **Formatted Output Variants**
  - Provide colorized output for terminal display
  - Include HTML formatted version
  - Add structured diff information
  - Provide message as array of lines

### Lower Priority - Nice to Have

- [ ] **Test Environment Context**
  - RSpec configuration settings
  - Random seed value
  - Applied filters/exclusions

- [ ] **Performance Data**
  - Memory usage (if tracked)
  - Database query counts (if instrumented)
  - Resource utilization metrics

- [ ] **Enhanced Backtrace Information**
  - Full backtrace (not just formatted)
  - Backtrace with/without filtering
  - Source code snippets around failure

## Implementation Considerations

### Backwards Compatibility
- All additions should be in new fields
- Existing JSON structure must remain unchanged
- Use feature flags or configuration options for new data

### Performance Impact
- Additional data extraction should be lazy
- Avoid expensive operations unless explicitly requested
- Consider memory usage for large test suites

### Configuration Options
- Allow users to opt-in to additional data
- Provide presets (minimal, standard, full)
- Support field-level inclusion/exclusion

## Example Enhanced Output Structure

```json
{
  "examples": [{
    "id": "spec/models/user_spec.rb[1:2:1]",
    "description": "validates email format",
    "full_description": "User validations validates email format",
    "status": "failed",
    
    // Location variants
    "file_path": "./spec/models/user_spec.rb",
    "line_number": 42,
    "location": "./spec/models/user_spec.rb:42",
    "absolute_file_path": "/Users/john/projects/myapp/spec/models/user_spec.rb",
    "rerun_file_path": "./spec/models/user_spec.rb:42",
    
    // Timing
    "run_time": 0.023,
    "started_at": "2024-01-15T10:30:45.123Z",
    "finished_at": "2024-01-15T10:30:45.146Z",
    
    // Custom metadata
    "metadata": {
      "type": "model",
      "priority": "high",
      "slow": true,
      "db": true,
      "jira": "PROJ-123"
    },
    
    // Enhanced failure data
    "exception": {
      "class": "RSpec::Expectations::ExpectationNotMetError",
      "message": "expected: true\n     got: false",
      "backtrace": ["..."],
      "formatted_output": {
        "plain": "expected: true\n     got: false",
        "colorized": "\e[31mexpected: true\e[0m\n\e[31m     got: false\e[0m",
        "message_lines": ["expected: true", "     got: false"]
      }
    },
    
    // Structured data (current enhancement)
    "structured_data": {
      "expected": true,
      "actual": false,
      "matcher_name": "RSpec::Matchers::BuiltIn::Eq",
      "matcher_details": {
        "diffable": true,
        "supports_block_expectations": false
      },
      "aggregate_failures": [
        {
          "expected": "valid@email.com",
          "actual": "invalid-email",
          "matcher_name": "RSpec::Matchers::BuiltIn::Match",
          "message": "expected 'invalid-email' to match /\\A[^@]+@[^@]+\\z/"
        }
      ]
    }
  }]
}
```
