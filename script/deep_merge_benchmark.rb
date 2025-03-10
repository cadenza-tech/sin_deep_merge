# frozen_string_literal: true

require 'json'
require 'benchmark/ips'
require 'deep_merge'
require_relative 'benchmarks'

result = {}

BENCHMARKS.each do |key, value|
  report = Benchmark.ips do |x|
    x.quiet = true

    x.report('DeepMerge - deep_merge') do |times|
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

File.write(File.expand_path('../tmp/deep_merge_benchmark_results.json', __dir__), JSON.pretty_generate(result))
