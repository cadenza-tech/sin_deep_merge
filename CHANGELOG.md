# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-08-10

### Added

- Add Ractor support (C, Java)
- Add `SinDeepMerge::Fallback` and route Hash subclasses that override `merge!` or `update` such as `ActiveSupport::HashWithIndifferentAccess` through it (C, Java)

### Fixed

- Merge nested hashes into copies in `deep_merge!` so that a shared or frozen nested hash is never mutated in place (C)
- Raise `TypeError` for non-Hash argument (C)
- Raise `SystemStackError` instead of crashing on deeply nested hashes (Java)
- Prevent crash on repeated stack overflow (C)
- Fix `ClassCastException` for non-Symbol keys (Java)
- Align `deep_merge` and `deep_merge!` arity across C and Java
- Load Java extension without `JRuby::Util.load_ext`
- Include files under lib in packaged gem
- Install C extension under `sin_deep_merge` directory
- Keep stray compiled jar out of packaged gem

### Changed

- Optimize block invocation by yielding directly instead of allocating a Proc (C)
- Skip `initialize_dup` when copying hashes (C)
- Simplify native extension loading
- Improve readability of C extension
- Remove unneeded json gem dependency
- Minimize gem version constraints
- Add JRuby build and test script
- Make test task depend on compile
- Recompile jar
- Rework benchmark to compare like for like and report measurement error
- Add Ractor, Hash subclass and key type test coverage
- Update Ruby and JRuby versions in CI matrix
- Verify committed jar matches Java source in CI
- Require tests to pass before releasing in CI
- Pin `google-java-format` version and fail on download errors in CI
- Update `actions/checkout` v6 to v7 in CI
- Remove assign workflow
- Update sponsor link to GitHub Sponsors
- Update README.md
- Update .gitignore
- Update .rubocop.yml

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

[2.0.0]: https://github.com/cadenza-tech/sin_deep_merge/compare/v1.0.2...v2.0.0
[1.0.2]: https://github.com/cadenza-tech/sin_deep_merge/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/cadenza-tech/sin_deep_merge/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/cadenza-tech/sin_deep_merge/compare/v0.0.2...v1.0.0
[0.0.2]: https://github.com/cadenza-tech/sin_deep_merge/compare/v0.0.1...v0.0.2
[0.0.1]: https://github.com/cadenza-tech/sin_deep_merge/compare/v0.0.0...v0.0.1
[0.0.0]: https://github.com/cadenza-tech/sin_deep_merge/releases/tag/v0.0.0
