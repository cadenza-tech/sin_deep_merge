# frozen_string_literal: true

require 'json'
require 'benchmark/ips'
require_relative 'benchmarks'

class Hash
  def deep_merge(other_hash)
    merged = dup
    other_hash.each do |key, value|
      if merged[key].is_a?(Hash) && value.is_a?(Hash)
        merged[key] = merged[key].deep_merge(value)
      else
        merged[key] = value
      end
    end
    merged
  end
end

result = {}

BENCHMARKS.each do |key, value|
  report = Benchmark.ips do |x|
    x.quiet = true

    x.report('Scratch - deep_merge') do |times|
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

File.write(File.expand_path('../tmp/scratch_benchmark_results.json', __dir__), JSON.pretty_generate(result))
