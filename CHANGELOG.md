# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
