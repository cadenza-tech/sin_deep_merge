# frozen_string_literal: true

require 'benchmark/ips'
require 'terminal-table'
require_relative 'benchmark_helper'
require_relative 'benchmark_hashes'

class DeepMergeBenchmark
  SPEED_RATIO_THRESHOLD = 0.1

  BENCHMARK_METHODS = {
    'ActiveSupport' => :deep_merge,
    'DeepMerge' => :dm_deep_merge,
    'SinDeepMerge' => :sin_deep_merge,
    'Scratch' => :scratch_deep_merge
  }.freeze

  def self.run
    new.run
  end

  def run
    results = execute_benchmarks
    display_results(results)
  end

  private

  def execute_benchmarks
    results = {}

    BENCHMARKS.each do |name, hashes|
      puts "Benchmarking: #{name}..."

      if hashes.length < 3
        report = run_benchmark(hashes[0], hashes[1])
      else
        report = run_benchmark_with_block(hashes[0], hashes[1], hashes[2], name)
      end
      results[name] = extract_results(report)
    end

    results
  end

  def run_benchmark(hash1, hash2)
    Benchmark.ips do |x|
      x.time = 1
      x.warmup = 0.5
      x.quiet = true

      BENCHMARK_METHODS.each do |lib_name, method|
        x.report("#{lib_name} - deep_merge") do |times|
          i = 0
          while i < times
            hash1.send(method, hash2)
            i += 1
          end
        end
      end
    end
  end

  def run_benchmark_with_block(hash1, hash2, block, block_name)
    Benchmark.ips do |x|
      x.time = 1
      x.warmup = 0.5
      x.quiet = true

      BENCHMARK_METHODS.each do |lib_name, method|
        x.report("#{lib_name} - deep_merge (#{block_name})") do |times|
          i = 0
          while i < times
            hash1.send(method, hash2, &block)
            i += 1
          end
        end
      end
    end
  end

  def extract_results(report)
    report.entries.map { |entry| [entry.label, entry.ips] }.to_h
  end

  def display_results(all_results)
    all_results.each do |test_name, results|
      table = create_result_table(test_name, results)
      puts "\n#{table}"
    end
  end

  def create_result_table(test_name, results)
    Terminal::Table.new(
      title: "Benchmark Result: #{test_name}",
      headings: ['Name', 'Iteration Per Second', 'Speed Ratio'],
      rows: format_result_rows(results)
    )
  end

  def format_result_rows(results)
    sorted_results = results.sort_by { |_key, value| value }.reverse
    fastest_speed = sorted_results.first[1]
    sorted_results.map do |key, value|
      [key, format('%.1f', value), calculate_speed_ratio(fastest_speed, value)]
    end
  end

  def calculate_speed_ratio(fastest_speed, current_speed)
    speed_ratio = fastest_speed / current_speed
    return 'Fastest' if speed_ratio - 1 < SPEED_RATIO_THRESHOLD

    "#{speed_ratio.round(1)}x slower"
  end
end

DeepMergeBenchmark.run if __FILE__ == $PROGRAM_NAME
