# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2026-02-22

### Changed

- Recompile jar

## [1.0.1] - 2026-02-21

### Fixed

- Add frozen check for `deep_merge!` to raise `FrozenError` on frozen Hash (C, Java)
- Fix `deep_merge!` in Java to modify nested hashes in-place instead of duplicating them

### Changed

- Optimize block invocation in C by using `rb_funcallv` instead of `rb_proc_call` with temporary Array allocation
- Optimize hash lookup in Java by using `fastARef` instead of `op_aref`
- Skip `to_hash` conversion when argument is already a Hash (C)
- Add `Check_Type` validation after `to_hash` conversion to ensure type safety (C)
- Use previously unused `id_call` variable for block invocation via `rb_funcallv` (C)
- Add TruffleRuby compatibility (Gemfile, C)
- Pin gem versions in Gemfile
- Refactor benchmark scripts into a single unified runner
- Add `.clang-format` configuration
- Add C and Java lint to CI (`clang-format`, `google-java-format`)
- Update `actions/checkout` v4 to v6 in CI
- Update .gitignore
- Update README.md benchmark results

## [1.0.0] - 2025-08-11

### Changed

- Improve performance

### Fixed

- Update tests
- Update .gitignore
- Improve lint CI
- Update README.md

## [0.0.2] - 2025-03-18

### Changed

- Update summary

## [0.0.1] - 2025-03-12

### Fixed

- Fix permission

### Changed

- Update tests
- Update summary
- Update README.md

## [0.0.0] - 2025-03-11

### Added

- Initial release

[1.0.2]: https://github.com/cadenza-tech/sin_deep_merge/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/cadenza-tech/sin_deep_merge/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/cadenza-tech/sin_deep_merge/compare/v0.0.2...v1.0.0
[0.0.2]: https://github.com/cadenza-tech/sin_deep_merge/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/cadenza-tech/sin_deep_merge/compare/v0.0.0...v0.0.1
[0.0.0]: https://github.com/cadenza-tech/sin_deep_merge/releases/tag/v0.0.0
