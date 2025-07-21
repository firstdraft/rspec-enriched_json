# Claude Instructions

This file contains instructions for Claude when working on this project.

## Git Commit Guidelines

- **NEVER mention Claude in git commit messages**
- Keep commit messages under 50 characters in subject line
- Use good git commit style (imperative mood, descriptive)
- Focus on what the commit does, not who made it
- **Always run `bundle exec standardrb --fix` before committing**
- Ensure `bundle exec standardrb` passes with no violations

## Project Context

This project creates a universal JSON output system for RSpec matchers:

### Key Files
- `lib/rspec/enriched_json.rb` - Main entry point that loads all components
- `lib/rspec/enriched_json/expectation_helper_wrapper.rb` - Universal wrapper that intercepts all matcher failures
- `lib/rspec/enriched_json/enriched_expectation_not_met_error.rb` - Custom error class for structured data
- `lib/rspec/enriched_json/formatters/enriched_json_formatter.rb` - JSON formatter that outputs enriched data
- `rspec-enriched_json.gemspec` - Gem specification
- `spec/` - Test suite with integration and unit tests
- `demo.rb` - Demo script showing various failure types
- `Gemfile` - Dependencies (rspec, standard)
- `.standard.yml` - StandardRB configuration

### Technical Approach
1. **Universal wrapper** intercepts all matcher failures via `ExpectationHelper.handle_failure`
2. **Custom error class** (`EnrichedExpectationNotMetError`) carries structured data through the failure chain
3. **Automatic data extraction** from matchers that have `expected` and `actual` methods
4. **Graceful degradation** for matchers without expected/actual methods
5. **Enhanced formatter** extends RSpec's JsonFormatter to include structured data

### Key Discoveries from Development
- RSpec doesn't expose expected/actual values as structured data by default
- Diffs are embedded in failure message strings, not available separately  
- Custom messages completely replace default messages
- Universal wrapper approach works better than BaseMatcher-only approach
- Module prepending allows interception without breaking existing behavior

### JSON Output Structure
All matchers output standardized JSON with:
- `expected` - Serialized expected value
- `actual` - Serialized actual value  
- `original_message` - The matcher's original failure message (only populated when a custom message is provided)
- `matcher_name` - Class name of the matcher

### Object Serialization
- Primitives: strings, numbers, booleans, nil (as-is)
- Symbols: converted to strings
- Arrays/Hashes: recursively serialized (with size limits)
- Objects: serialized with class name, inspect, to_s, and instance variables (for objects with ≤10 instance variables)
- Structs: special handling with `struct_values` field

### Best Practices Established
- Custom matchers should implement `expected` and `actual` methods for automatic data extraction
- Use rich expected values (hashes, objects) for better context
- Test with various matcher types to ensure universal compatibility
- The gem works transparently with all existing matchers without modification

## Development History

1. Started with exploration of RSpec formatter hooks and available data
2. Created MaxJsonFormatter to capture all possible structure  
3. Discovered limitations with expected/actual values only being strings
4. Implemented BaseMatcher patching for structured data extraction
5. Added universal wrapper to support ALL matcher types
6. Consolidated multiple approaches into single comprehensive solution
7. Cleaned up obsolete files and unified documentation

## Goals Achieved

- ✅ Extract maximum possible structure from RSpec test runs
- ✅ Provide JSON output with expected/actual values as structured data  
- ✅ Support ALL matcher types (built-in, DSL, custom, third-party)
- ✅ Preserve original behavior while adding JSON functionality
- ✅ Create comprehensive guide for custom matcher development
- ✅ Establish clean, maintainable codebase structure

