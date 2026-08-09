# SinDeepMerge

[![License](https://img.shields.io/github/license/cadenza-tech/sin_deep_merge?label=License&labelColor=343B42&color=blue)](https://github.com/cadenza-tech/sin_deep_merge/blob/main/LICENSE.txt) [![Tag](https://img.shields.io/github/tag/cadenza-tech/sin_deep_merge?label=Tag&logo=github&labelColor=343B42&color=2EBC4F)](https://github.com/cadenza-tech/sin_deep_merge/blob/main/CHANGELOG.md) [![Release](https://github.com/cadenza-tech/sin_deep_merge/actions/workflows/release.yml/badge.svg)](https://github.com/cadenza-tech/sin_deep_merge/actions?query=workflow%3Arelease) [![Test](https://github.com/cadenza-tech/sin_deep_merge/actions/workflows/test.yml/badge.svg)](https://github.com/cadenza-tech/sin_deep_merge/actions?query=workflow%3Atest) [![Lint](https://github.com/cadenza-tech/sin_deep_merge/actions/workflows/lint.yml/badge.svg)](https://github.com/cadenza-tech/sin_deep_merge/actions?query=workflow%3Alint)

Merge deeply nested hashes faster than DeepMerge or ActiveSupport.

- [Installation](#installation)
- [Usage](#usage)
  - [Hash#deep\_merge](#hashdeep_merge)
  - [Hash#deep\_merge!](#hashdeep_merge-1)
- [Benchmark](#benchmark)
- [Changelog](#changelog)
- [Development](#development)
  - [Building for JRuby](#building-for-jruby)
- [Contributing](#contributing)
- [License](#license)
- [Code of Conduct](#code-of-conduct)
- [Sponsor](#sponsor)

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add sin_deep_merge
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install sin_deep_merge
```

## Usage

Both methods can be called inside non-main Ractors on CRuby 3.0+.

Requiring ActiveSupport afterwards is safe from 7.1 on, where Hash reaches both methods through `ActiveSupport::DeepMergeable` and a method defined on Hash itself wins over an included module. Up to 7.0 ActiveSupport defines them on Hash directly and replaces these when `active_support/core_ext/hash/deep_merge` is loaded last, so require `sin_deep_merge` after ActiveSupport there. `Hash.instance_method(:deep_merge).source_location` is `nil` while the extension is the one in place.

### Hash#deep_merge

SinDeepMerge's Hash#deep_merge is compatible with ActiveSupport's Hash#deep_merge.

Hash subclasses that override `merge!` or `update`, such as `ActiveSupport::HashWithIndifferentAccess`, are merged through that override, so they behave the same as with ActiveSupport. Such a merge runs in Ruby rather than in the extension, so it is no faster than ActiveSupport.

What SinDeepMerge recurses into is any pair of Hashes, where ActiveSupport asks its `deep_merge?` hook instead. Two cases follow from that: a value that includes `ActiveSupport::DeepMergeable` without being a Hash is replaced rather than merged into, and a Hash subclass that overrides `deep_merge?` to refuse a value is merged into all the same.

```ruby
require 'sin_deep_merge'

hash1 = { a: 1, b: '2', c: :three, d: true, e: nil }
hash2 = { b: :two, c: nil, d: false, e: 0, f: 'f' }
hash1.deep_merge(hash2) # => { a: 1, b: :two, c: nil, d: false, e: 0, f: 'f' }

hash1 = { a: [1, 2], b: [3, 4] }
hash2 = { a: [3, 4], b: 5 }
hash1.deep_merge(hash2) # => { a: [3, 4], b: 5 }

hash1 = { a: { b: 1, c: 2 }, b: { c: 3 } }
hash2 = { a: { c: 3, d: 4 }, b: 5 }
hash1.deep_merge(hash2) # => { a: { b: 1, c: 3, d: 4 }, b: 5 }

hash1 = { a: 1, b: 2 }
hash2 = { b: 3, c: 4 }
hash1.deep_merge(hash2) { |_key, old_val, new_val| old_val + new_val } # => { a: 1, b: 5, c: 4 }

hash1 = { a: [1, 2], b: 3 }
hash2 = { a: [3, 4], b: 5 }
hash1.deep_merge(hash2) do |_key, old_val, new_val|
  if old_val.is_a?(Array) && new_val.is_a?(Array)
    old_val + new_val
  else
    new_val
  end
end # => { a: [1, 2, 3, 4], b: 5 }
```

### Hash#deep_merge!

SinDeepMerge's Hash#deep_merge! is compatible with ActiveSupport's Hash#deep_merge!.

Hash#deep_merge! destructively updates self by merging new values into it. Like ActiveSupport, nested hashes are merged into copies, so a nested hash shared with another object or a frozen nested hash is never mutated in place.

One case differs: a plain Hash carrying a singleton `merge!` is written into by the extension, so that override never runs, where ActiveSupport reaches it. Hash#deep_merge is not affected, since ActiveSupport merges into a `dup` there, and a `dup` no longer carries the singleton method.

## Benchmark

SinDeepMerge's Hash#deep_merge is about 2.5-2.7x faster than ActiveSupport's Hash#deep_merge, and SinDeepMerge's Hash#deep_merge! is about 4.4x faster than DeepMerge's Hash#deep_merge! and about 2.4x faster than ActiveSupport's Hash#deep_merge!.

The first four tables hold only methods that leave the hash they were called on alone, so every iteration of the timed loop repeats the work of the first. DeepMerge is absent from them because it has no such method: its Hash#deep_merge writes into the receiver and returns it, the same as its Hash#deep_merge!. It also reads its second argument as an options Hash rather than as a block, so it has no block form either.

The last table is the one DeepMerge belongs in. Its entry there is Hash#deep_merge! rather than Hash#deep_merge, because Hash#deep_merge leaves an existing value alone where the other two overwrite it, and on these inputs it would walk the hash without writing anything. Every row there merges into a receiver that already carries the merge from the second iteration on. These inputs keep their shape once merged, so that costs little, but an input that grew the receiver would flatter each library by a different amount. Read those ratios as the rough comparison they are rather than as the measurement the first four tables give.

```bash
$ bundle exec rake benchmark
Benchmarking: Shallow Recursion...
Benchmarking: Shallow Recursion With Block...
Benchmarking: Deep Recursion...
Benchmarking: Deep Recursion With Block...
Benchmarking: Deep Recursion In Place...

+--------------------------------------------------------------------------+
|                   Benchmark Result (Shallow Recursion)                   |
+----------------------------+----------------------+--------+-------------+
| Name                       | Iteration Per Second | Error  | Speed Ratio |
+----------------------------+----------------------+--------+-------------+
| SinDeepMerge - deep_merge  | 2678917.7            | ±0.56% | Fastest     |
| Scratch - deep_merge       | 1251682.2            | ±0.55% | 2.1x slower |
| ActiveSupport - deep_merge | 1006374.4            | ±0.53% | 2.7x slower |
+----------------------------+----------------------+--------+-------------+

+---------------------------------------------------------------------------------------------------------+
|                             Benchmark Result (Shallow Recursion With Block)                             |
+-----------------------------------------------------------+----------------------+--------+-------------+
| Name                                                      | Iteration Per Second | Error  | Speed Ratio |
+-----------------------------------------------------------+----------------------+--------+-------------+
| SinDeepMerge - deep_merge (Shallow Recursion With Block)  | 2283373.8            | ±0.62% | Fastest     |
| Scratch - deep_merge (Shallow Recursion With Block)       | 1100891.3            | ±0.50% | 2.1x slower |
| ActiveSupport - deep_merge (Shallow Recursion With Block) | 913719.8             | ±0.68% | 2.5x slower |
+-----------------------------------------------------------+----------------------+--------+-------------+

+--------------------------------------------------------------------------+
|                    Benchmark Result (Deep Recursion)                     |
+----------------------------+----------------------+--------+-------------+
| Name                       | Iteration Per Second | Error  | Speed Ratio |
+----------------------------+----------------------+--------+-------------+
| SinDeepMerge - deep_merge  | 28403.8              | ±0.78% | Fastest     |
| Scratch - deep_merge       | 12948.1              | ±0.76% | 2.2x slower |
| ActiveSupport - deep_merge | 11271.6              | ±0.45% | 2.5x slower |
+----------------------------+----------------------+--------+-------------+

+------------------------------------------------------------------------------------------------------+
|                             Benchmark Result (Deep Recursion With Block)                             |
+--------------------------------------------------------+----------------------+--------+-------------+
| Name                                                   | Iteration Per Second | Error  | Speed Ratio |
+--------------------------------------------------------+----------------------+--------+-------------+
| SinDeepMerge - deep_merge (Deep Recursion With Block)  | 27810.9              | ±0.58% | Fastest     |
| Scratch - deep_merge (Deep Recursion With Block)       | 12943.0              | ±0.47% | 2.1x slower |
| ActiveSupport - deep_merge (Deep Recursion With Block) | 10803.1              | ±0.56% | 2.6x slower |
+--------------------------------------------------------+----------------------+--------+-------------+

+---------------------------------------------------------------------------+
|                Benchmark Result (Deep Recursion In Place)                 |
+-----------------------------+----------------------+--------+-------------+
| Name                        | Iteration Per Second | Error  | Speed Ratio |
+-----------------------------+----------------------+--------+-------------+
| SinDeepMerge - deep_merge!  | 27075.8              | ±0.66% | Fastest     |
| ActiveSupport - deep_merge! | 11284.2              | ±0.44% | 2.4x slower |
| DeepMerge - deep_merge!     | 6089.0               | ±0.62% | 4.4x slower |
+-----------------------------+----------------------+--------+-------------+
```

Each row's error is how much its own measurement moved within that run, which is not how far that run sits from the next one. A run taken while the machine was busy reported errors just as narrow as these and ratios well away from these, so the numbers above are from a quiet machine and from two runs that agreed to within 0.1.

The error is also what decides the Speed Ratio column: a row is labelled Fastest when its gap to the top row is narrower than the two errors together, because a gap that small is the measurement failing to separate them rather than a difference it found. More than one row can therefore read Fastest.

The benchmark was executed in the following environment:

- Ruby 4.0.6 (2026-07-14 revision 03b6d3f889) +YJIT +PRISM [arm64-darwin25]
- DeepMerge 1.2.2
- ActiveSupport 8.1.3.1

## Changelog

See [CHANGELOG.md](https://github.com/cadenza-tech/sin_deep_merge/blob/main/CHANGELOG.md).

## Development

### Building for JRuby

To build the Java extension and run tests for JRuby support:

```bash
./script/jruby_build_and_test.sh
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cadenza-tech/sin_deep_merge. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/cadenza-tech/sin_deep_merge/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/cadenza-tech/sin_deep_merge/blob/main/LICENSE.txt).

## Code of Conduct

Everyone interacting in the SinDeepMerge project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/cadenza-tech/sin_deep_merge/blob/main/CODE_OF_CONDUCT.md).

## Sponsor

You can sponsor this project on [GitHub Sponsors](https://github.com/sponsors/cadenza-tech).
