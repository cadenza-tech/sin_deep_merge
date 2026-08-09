# frozen_string_literal: true

require 'benchmark/ips'
require 'terminal-table'
require_relative 'benchmark_helper'
require_relative 'benchmark_hashes'

class DeepMergeBenchmark
  SPEED_RATIO_THRESHOLD = 0.1
  WARMUP_SECONDS = 5
  TIME_SECONDS = 5
  # Only the non-destructive method of each library. Measuring deep_merge! alongside it needs a pristine receiver per call, which no
  # amount of setup can provide from inside a timed loop, and benchmark-ips keeps one entry per label, so the two would collide anyway.
  BENCHMARK_METHODS = {
    'DeepMerge' => :dm_deep_merge,
    'SinDeepMerge' => :sin_deep_merge,
    'ActiveSupport' => :deep_merge,
    'Scratch' => :scratch_deep_merge
  }.freeze
  # DeepMerge reads its second argument as an options Hash and has no block form, so it would sit in the block tables without doing the
  # work they measure.
  BLOCK_CAPABLE_LIBRARIES = (BENCHMARK_METHODS.keys - ['DeepMerge']).freeze
  # Sending the method name on each iteration measures the dispatch along with the merge, and it costs whichever library is fastest the
  # most. These loops name the method outright instead. benchmark-ips enters one of them once per cycle, so the public_send that picks
  # the loop is paid once per batch rather than once per call.
  LOOPS = Module.new do
    BENCHMARK_METHODS.each_value do |method|
      module_eval(
        # def self.#{method}(subject, other, times)
        #   i = 0
        #   while i < times
        #     subject.#{method}(other)
        #     i += 1
        #   end
        # end
        #
        # def self.#{method}_with_block(subject, other, times, block)
        #   i = 0
        #   while i < times
        #     subject.#{method}(other, &block)
        #     i += 1
        #   end
        # end
        <<~RUBY, __FILE__, __LINE__ + 1
          def self.#{method}(subject, other, times)
            i = 0
            while i < times
              subject.#{method}(other)
              i += 1
            end
          end

          def self.#{method}_with_block(subject, other, times, block)
            i = 0
            while i < times
              subject.#{method}(other, &block)
              i += 1
            end
          end
        RUBY
      )
    end
  end

  def self.run
    new.run
  end

  def run
    display_results(run_benchmarks)
  end

  private

  def run_benchmarks
    BENCHMARKS.each_with_object({}) do |(name, hashes), results|
      puts "Benchmarking: #{name}..."

      hash1, hash2, block = hashes
      if block
        report = run_benchmark_with_block(hash1, hash2, block, name)
      else
        report = run_benchmark(hash1, hash2)
      end

      results[name] = report.entries.map { |entry| [entry.label, entry.ips] }.to_h
    end
  end

  def run_benchmark(hash1, hash2)
    Benchmark.ips do |x|
      configure(x)

      BENCHMARK_METHODS.each do |lib_name, method|
        subject, other = fresh_inputs(hash1, hash2)

        x.report("#{lib_name} - deep_merge") { |times| LOOPS.public_send(method, subject, other, times) }
      end
    end
  end

  def run_benchmark_with_block(hash1, hash2, block, block_name)
    Benchmark.ips do |x|
      configure(x)

      BLOCK_CAPABLE_LIBRARIES.each do |lib_name|
        method = BENCHMARK_METHODS[lib_name]
        subject, other = fresh_inputs(hash1, hash2)

        x.report("#{lib_name} - deep_merge (#{block_name})") do |times|
          LOOPS.public_send(:"#{method}_with_block", subject, other, times, block)
        end
      end
    end
  end

  def configure(job)
    job.warmup = WARMUP_SECONDS
    job.time = TIME_SECONDS
    job.quiet = true
  end

  # DeepMerge merges into the receiver even from its non-destructive method, so each report starts from a copy of its own rather than
  # from whatever the report before it left behind. Within its own report it does still merge into its own result from the second
  # iteration on, which nothing outside the timed loop can undo.
  def fresh_inputs(hash1, hash2)
    [deep_copy(hash1), deep_copy(hash2)]
  end

  # Arrays are copied too, since deep_merge writes into the one it finds on the receiver, and a report that shared it with the report
  # before would merge into a list that is already twice as long.
  def deep_copy(value)
    case value
    when Hash then value.each_with_object({}) { |(key, nested), copy| copy[key] = deep_copy(nested) }
    when Array then value.map { |nested| deep_copy(nested) }
    else value
    end
  end

  def display_results(all_results)
    all_results.each do |test_name, results|
      table = create_result_table(test_name, results)
      puts "\n#{table}"
    end
  end

  def create_result_table(test_name, results)
    Terminal::Table.new(
      title: "Benchmark Result (#{test_name})",
      headings: ['Name', 'Iteration Per Second', 'Speed Ratio'],
      rows: format_result_rows(results)
    )
  end

  def format_result_rows(results)
    sorted_results = results.sort_by { |_key, value| value }.reverse
    fastest_speed = sorted_results.first[1]
    sorted_results.map { |key, value| [key, format('%.1f', value), calculate_speed_ratio(fastest_speed, value)] }
  end

  def calculate_speed_ratio(fastest_speed, current_speed)
    speed_ratio = fastest_speed / current_speed
    return 'Fastest' if speed_ratio - 1 < SPEED_RATIO_THRESHOLD

    "#{speed_ratio.round(1)}x slower"
  end
end

DeepMergeBenchmark.run if __FILE__ == $PROGRAM_NAME
