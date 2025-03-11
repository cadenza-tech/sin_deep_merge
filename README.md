# SinDeepMerge

[![License](https://img.shields.io/github/license/cadenza-tech/sin_deep_merge?label=License&labelColor=343B42&color=blue)](https://github.com/cadenza-tech/sin_deep_merge/blob/main/LICENSE.txt) [![Tag](https://img.shields.io/github/tag/cadenza-tech/sin_deep_merge?label=Tag&logo=github&labelColor=343B42&color=2EBC4F)](https://github.com/cadenza-tech/sin_deep_merge/blob/main/CHANGELOG.md) [![Release](https://github.com/cadenza-tech/sin_deep_merge/actions/workflows/release.yml/badge.svg)](https://github.com/cadenza-tech/sin_deep_merge/actions?query=workflow%3Arelease) [![Test](https://github.com/cadenza-tech/sin_deep_merge/actions/workflows/test.yml/badge.svg)](https://github.com/cadenza-tech/sin_deep_merge/actions?query=workflow%3Atest) [![Lint](https://github.com/cadenza-tech/sin_deep_merge/actions/workflows/lint.yml/badge.svg)](https://github.com/cadenza-tech/sin_deep_merge/actions?query=workflow%3Alint)

Ruby extension library for up to 2x faster deep merging of Hash objects than ActiveSupport.

- [Installation](#installation)
- [Usage](#usage)
  - [Hash#deep\_merge](#hashdeep_merge)
  - [Hash#deep\_merge!](#hashdeep_merge-1)
- [Benchmark](#benchmark)
- [Changelog](#changelog)
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

### Hash#deep_merge

SinDeepMerge's Hash#deep_merge is compatible with ActiveSupport's Hash#deep_merge.

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

Hash#deep_merge! destructively updates self by merging new values directly into it.

## Benchmark

SinDeepMerge's Hash#deep_merge is about 1.5-1.7x faster than ActiveSupport's Hash#deep_merge and about 3.6-5.3x faster than DeepMerge's Hash#deep_merge.

```bash
$ bundle exec rake benchmark

+-----------------------------------------------------------------+
|              Benchmark Result (Shallow Recursion)               |
+----------------------------+----------------------+-------------+
| Name                       | Iteration Per Second | Speed Ratio |
+----------------------------+----------------------+-------------+
| SinDeepMerge - deep_merge  | 1899218.6            | -           |
| Scratch - deep_merge       | 1289196.4            | 1.5x slower |
| ActiveSupport - deep_merge | 1215659.6            | 1.6x slower |
| DeepMerge - deep_merge     | 358813.8             | 5.3x slower |
+----------------------------+----------------------+-------------+

+-----------------------------------------------------------------+
|         Benchmark Result (Shallow Recursion With Block)         |
+----------------------------+----------------------+-------------+
| Name                       | Iteration Per Second | Speed Ratio |
+----------------------------+----------------------+-------------+
| SinDeepMerge - deep_merge  | 1594873.2            | -           |
| Scratch - deep_merge       | 1235536.5            | 1.3x slower |
| ActiveSupport - deep_merge | 1062621.4            | 1.5x slower |
| DeepMerge - deep_merge     | 356335.5             | 4.5x slower |
+----------------------------+----------------------+-------------+

+-----------------------------------------------------------------+
|                Benchmark Result (Deep Recursion)                |
+----------------------------+----------------------+-------------+
| Name                       | Iteration Per Second | Speed Ratio |
+----------------------------+----------------------+-------------+
| SinDeepMerge - deep_merge  | 23017.8              | -           |
| ActiveSupport - deep_merge | 14626.7              | 1.6x slower |
| Scratch - deep_merge       | 14271.6              | 1.6x slower |
| DeepMerge - deep_merge     | 6277.8               | 3.7x slower |
+----------------------------+----------------------+-------------+

+-----------------------------------------------------------------+
|          Benchmark Result (Deep Recursion With Block)           |
+----------------------------+----------------------+-------------+
| Name                       | Iteration Per Second | Speed Ratio |
+----------------------------+----------------------+-------------+
| SinDeepMerge - deep_merge  | 22727.1              | -           |
| Scratch - deep_merge       | 14154.0              | 1.6x slower |
| ActiveSupport - deep_merge | 13661.2              | 1.7x slower |
| DeepMerge - deep_merge     | 6279.9               | 3.6x slower |
+----------------------------+----------------------+-------------+
```

The benchmark was executed in the following environment:

`ruby 3.4.2 (2025-02-15 revision d2930f8e7a) +YJIT +PRISM [arm64-darwin24]`

## Changelog

See [CHANGELOG.md](https://github.com/cadenza-tech/sin_deep_merge/blob/main/CHANGELOG.md).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cadenza-tech/sin_deep_merge. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/cadenza-tech/sin_deep_merge/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/cadenza-tech/sin_deep_merge/blob/main/LICENSE.txt).

## Code of Conduct

Everyone interacting in the SinDeepMerge project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/cadenza-tech/sin_deep_merge/blob/main/CODE_OF_CONDUCT.md).

## Sponsor

You can sponsor this project on [Patreon](https://patreon.com/CadenzaTech).
