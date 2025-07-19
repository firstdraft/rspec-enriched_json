# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.7.0] - 2025-07-18

### Added
- Add `negated` flag to detect when `not_to` or `to_not` is used
- Add `passed` field to distinguish passing from failing tests in captured values

### Changed
- Major code simplification - removed unnecessary abstractions and comments
- Updated documentation to reflect actual features (removed non-existent performance limits)

### Fixed
- Fixed spec files that were causing false CI failures
- Updated integration tests to match current behavior

## [0.6.1] - 2025-07-18

### Added
- Capture expected/actual values for passing tests (not just failures)
- Memory-safe implementation with cleanup after formatter completes
- Special handling for Regexp serialization (human-readable format like `/pattern/flags`)
- Comprehensive test coverage for new features

### Fixed
- Fixed key mismatch bug between storage and retrieval of test values
- Fixed double-encoding issue in formatter that caused escaped strings in output

### Changed
- Upgraded to Oj for JSON serialization (better performance and object handling)
- Improved error handling with detailed fallback information

## [0.5.0] - 2025-06-26

### Changed
- **BREAKING**: Moved `diffable` to top level of details (from `details.diff_info.diffable` to `details.diffable`)

## [0.4.0] - 2025-06-26

### Changed
- **BREAKING**: Renamed output key from `enriched_with` to `details` for simplicity

## [0.3.0] - 2025-06-26

### Changed
- **BREAKING**: Renamed output key from `structured_data` to `enriched_with` for better clarity

## [0.2.0] - 2025-06-26

### Added
- Enhanced metadata capture (location, tags, hierarchy, described class)
- Robust error recovery during serialization with Serializer module
- diff_info.diffable field to help tools determine if values can be meaningfully diffed

### Changed
- Improved serialization error handling to prevent formatter crashes

## [0.1.0] - 2025-06-25

### Added
- Initial release of rspec-enriched_json
- Drop-in replacement for RSpec's built-in JSON formatter
- Structured data extraction for expectation failures
- Support for all RSpec built-in matchers
- Preservation of custom failure messages
- Rich object serialization (arrays, hashes, structs, custom objects)
- Full backward compatibility with existing JSON consumers
