# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2026-01-14

### Added
- Multi-line selection and editing support - select and edit text spanning multiple lines
- Comprehensive unit test suite using plenary.nvim
  - Tests for simple editing operations
  - Tests for change operations (c, cc, C, cw)
  - Tests for delete operations (x, dw)
  - Tests for replace operations (r, R)
  - Tests for paste operations (p, P)
  - Tests for visual block mode operations
  - Tests for line operations (Enter/line splitting)
  - Tests for append operations at extmark boundaries
  - Tests for mark synchronization after deletions
- Test runner script with comprehensive summary reporting

### Changed
- Improved mark synchronization logic to handle edge cases where `current_extmark` is nil
- Enhanced test infrastructure with detailed pass/fail/error counts and per-suite statistics

## [1.0.1] - Previous Release

### Added
- Initial stable release with core editing features
- Highlight current and all matched occurrences
- Simultaneous editing of multiple occurrences
- Navigation between occurrences
- Toggle individual occurrences
- Restrict occurrences to current function
- Full keyword selection in normal mode
- Substring selection in visual mode

[Unreleased]: https://github.com/viocost/viedit/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/viocost/viedit/releases/tag/v2.0.0
[1.0.1]: https://github.com/viocost/viedit/releases/tag/v1.0.1
