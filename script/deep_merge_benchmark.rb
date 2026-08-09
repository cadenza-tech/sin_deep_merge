# frozen_string_literal: true

require 'benchmark/ips'
require 'terminal-table'
require_relative 'benchmark_helper'
require_relative 'benchmark_hashes'

class DeepMergeBenchmark
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

      results[name] = report.entries.map { |entry| [entry.label, measurement(entry)] }.to_h
    end
  end

  def measurement(entry)
    { ips: entry.ips, error: entry.error_percentage }
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
      headings: ['Name', 'Iteration Per Second', 'Error', 'Speed Ratio'],
      rows: format_result_rows(results)
    )
  end

  def format_result_rows(results)
    sorted_results = results.sort_by { |_key, value| value[:ips] }.reverse
    fastest = sorted_results.first[1]
    sorted_results.map do |key, value|
      [key, format('%.1f', value[:ips]), format('±%.2f%%', value[:error]), calculate_speed_ratio(fastest, value)]
    end
  end

  # Two entries are indistinguishable when the noise both were measured with leaves them unseparated. The flat 10% this replaces was a
  # guess that took no account of how steady either measurement actually was.
  def calculate_speed_ratio(fastest, current)
    speed_ratio = (fastest[:ips] / current[:ips]).round(1)
    # A ratio that rounds to 1.0 reads as slower while saying the two ran at the same speed, so it is a tie on its own terms. It also
    # answers the fastest row, whose zero gap does not fall inside a zero-width band.
    return 'Fastest' if speed_ratio <= 1.0 || overlapping_error_bands?(fastest, current)

    "#{speed_ratio}x slower"
  end

  # The bands are compared as iterations rather than as the two percentages, which are each a share of a different mean: adding them
  # would shrink the fastest row's half of the band by exactly the ratio being judged.
  def overlapping_error_bands?(fastest, current)
    current[:ips] * (1 + (current[:error] / 100)) > fastest[:ips] * (1 - (fastest[:error] / 100))
  end
end

DeepMergeBenchmark.run if __FILE__ == $PROGRAM_NAME
