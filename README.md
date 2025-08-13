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

SinDeepMerge's Hash#deep_merge is about 6.8-12.0x faster than DeepMerge's Hash#deep_merge and about 2.8-4.8x faster than ActiveSupport's Hash#deep_merge.

```bash
$ bundle exec rake benchmark

+------------------------------------------------------------------+
|               Benchmark Result (Shallow Recursion)               |
+----------------------------+----------------------+--------------+
| Name                       | Iteration Per Second | Speed Ratio  |
+----------------------------+----------------------+--------------+
| SinDeepMerge - deep_merge  | 4906360.5            | Fastest      |
| Scratch - deep_merge       | 1394443.3            | 3.5x slower  |
| ActiveSupport - deep_merge | 1114420.2            | 4.4x slower  |
| DeepMerge - deep_merge     | 410338.3             | 12.0x slower |
+----------------------------+----------------------+--------------+

+------------------------------------------------------------------------------------------------+
|                        Benchmark Result (Shallow Recursion With Block)                         |
+-----------------------------------------------------------+----------------------+-------------+
| Name                                                      | Iteration Per Second | Speed Ratio |
+-----------------------------------------------------------+----------------------+-------------+
| SinDeepMerge - deep_merge (Shallow Recursion With Block)  | 2734823.1            | Fastest     |
| Scratch - deep_merge (Shallow Recursion With Block)       | 1378402.4            | 2.0x slower |
| ActiveSupport - deep_merge (Shallow Recursion With Block) | 972886.7             | 2.8x slower |
| DeepMerge - deep_merge (Shallow Recursion With Block)     | 401372.9             | 6.8x slower |
+-----------------------------------------------------------+----------------------+-------------+

+-----------------------------------------------------------------+
|                Benchmark Result (Deep Recursion)                |
+----------------------------+----------------------+-------------+
| Name                       | Iteration Per Second | Speed Ratio |
+----------------------------+----------------------+-------------+
| SinDeepMerge - deep_merge  | 63005.6              | Fastest     |
| Scratch - deep_merge       | 16103.6              | 3.9x slower |
| ActiveSupport - deep_merge | 13200.2              | 4.8x slower |
| DeepMerge - deep_merge     | 7003.9               | 9.0x slower |
+----------------------------+----------------------+-------------+

+---------------------------------------------------------------------------------------------+
|                        Benchmark Result (Deep Recursion With Block)                         |
+--------------------------------------------------------+----------------------+-------------+
| Name                                                   | Iteration Per Second | Speed Ratio |
+--------------------------------------------------------+----------------------+-------------+
| SinDeepMerge - deep_merge (Deep Recursion With Block)  | 58192.8              | Fastest     |
| Scratch - deep_merge (Deep Recursion With Block)       | 15931.3              | 3.7x slower |
| ActiveSupport - deep_merge (Deep Recursion With Block) | 12269.7              | 4.7x slower |
| DeepMerge - deep_merge (Deep Recursion With Block)     | 6997.5               | 8.3x slower |
+--------------------------------------------------------+----------------------+-------------+
```

The benchmark was executed in the following environment:

- Ruby 3.4.5 (2025-07-16 revision 20cda200d3) +YJIT +PRISM [arm64-darwin24]
- DeepMerge 1.2.2
- ActiveSupport 8.0.2

## Changelog

See [CHANGELOG.md](https://github.com/cadenza-tech/sin_deep_merge/blob/main/CHANGELOG.md).

## Development

### Building for JRuby

To build the Java extension for JRuby support, follow these steps:

1. Start a JRuby Docker container:

```bash
docker run -it --rm -v "$(pwd):/app" -w /app jruby:9.3.4.0-jdk8 /bin/bash
```

2. Install necessary dependencies:

```bash
apt update
apt upgrade
apt install git
```

3. Compile the Java source:

```bash
cd ext/java
javac -cp /opt/jruby/lib/jruby.jar sin_deep_merge/SinDeepMergeLibrary.java
```

4. Create the JAR file:

```bash
jar cvf ../../lib/sin_deep_merge/sin_deep_merge.jar sin_deep_merge/SinDeepMergeLibrary.class
```

5. Install dependencies and run linter, tests and benchmarks:

```bash
cd ../../
gem install bundler
bundle install
bundle exec rake rubocop
bundle exec rake test
bundle exec rake benchmark
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cadenza-tech/sin_deep_merge. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/cadenza-tech/sin_deep_merge/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/cadenza-tech/sin_deep_merge/blob/main/LICENSE.txt).

## Code of Conduct

Everyone interacting in the SinDeepMerge project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/cadenza-tech/sin_deep_merge/blob/main/CODE_OF_CONDUCT.md).

## Sponsor

You can sponsor this project on [Patreon](https://patreon.com/CadenzaTech).
