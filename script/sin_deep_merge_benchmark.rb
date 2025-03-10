# frozen_string_literal: true

$VERBOSE = nil

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'json'
require 'benchmark/ips'
require 'sin_deep_merge'
require_relative 'benchmarks'

result = {}

BENCHMARKS.each do |key, value|
  report = Benchmark.ips do |x|
    x.quiet = true

    x.report('SinDeepMerge - deep_merge') do |times|
      i = 0
      while i < times
        value[0].deep_merge(value[1], &value[2])
        i += 1
      end
    end
  end

  report.entries.each do |entry|
    result[key] = { entry.label => entry.ips }
  end
end

File.write(File.expand_path('../tmp/sin_deep_merge_benchmark_results.json', __dir__), JSON.pretty_generate(result))
