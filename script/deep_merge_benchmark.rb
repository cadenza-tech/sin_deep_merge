# frozen_string_literal: true

require 'benchmark/ips'
require 'terminal-table'
require_relative 'benchmark_helper'
require_relative 'benchmark_hashes'

class DeepMergeBenchmark
  WARMUP_SECONDS = 5
  TIME_SECONDS = 5
  # Above this the ratios move from one run to the next, so the table is not one to copy into the README. Every row prints its own error
  # either way, but reading each of them is the check that gets skipped.
  ERROR_PERCENTAGE_THRESHOLD = 5.0
  # Each of these leaves the hash it was called on alone, so every iteration of a timed loop repeats the work of the first. DeepMerge is
  # absent because it has no such method: its deep_merge writes into the receiver and returns it, the same as its deep_merge!.
  NON_DESTRUCTIVE_METHODS = {
    'SinDeepMerge' => :sin_deep_merge,
    'ActiveSupport' => :deep_merge,
    'Scratch' => :scratch_deep_merge
  }.freeze
  # The one table DeepMerge belongs in. DeepMerge's own deep_merge is not the entry here: it leaves an existing value alone where the
  # other two overwrite it, so on these inputs it would walk the hash without writing anything. Every row here merges into a receiver
  # that already carries the merge from the second iteration on. These inputs keep their shape once merged, so that costs little, but an
  # input that grew the receiver would flatter each library by a different amount. Read these ratios as the rough comparison they are
  # rather than as the measurement the tables above give.
  DESTRUCTIVE_METHODS = {
    'DeepMerge' => :dm_deep_merge!,
    'SinDeepMerge' => :sin_deep_merge!,
    'ActiveSupport' => :deep_merge!
  }.freeze
  # One input carries the destructive table, since that limitation is the same whichever hashes go into it.
  DESTRUCTIVE_BENCHMARK = 'Deep Recursion'
  ALL_METHODS = (NON_DESTRUCTIVE_METHODS.values + DESTRUCTIVE_METHODS.values).freeze
  # Sending the method name on each iteration measures the dispatch along with the merge, and it costs whichever library is fastest the
  # most. These loops name the method outright instead. benchmark-ips enters one of them once per cycle, so the public_send that picks
  # the loop is paid once per batch rather than once per call.
  LOOPS = Module.new do
    ALL_METHODS.each do |method|
      module_eval(
        # def self.#{method}(subject, other, times)
        #   i = 0
        #   while i < times
        #     subject.#{method}(other)
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
        RUBY
      )
    end

    # Only the non-destructive tables take a block, which is just as well: a name ending in ! could not carry the suffix.
    NON_DESTRUCTIVE_METHODS.each_value do |method|
      module_eval(
        # def self.#{method}_with_block(subject, other, times, block)
        #   i = 0
        #   while i < times
        #     subject.#{method}(other, &block)
        #     i += 1
        #   end
        # end
        <<~RUBY, __FILE__, __LINE__ + 1
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
    non_destructive_results.merge(destructive_results)
  end

  def non_destructive_results
    BENCHMARKS.each_with_object({}) do |(name, hashes), results|
      puts "Benchmarking: #{name}..."

      hash1, hash2, block = hashes
      if block
        report = run_benchmark_with_block(hash1, hash2, block, name)
      else
        report = run_benchmark(hash1, hash2)
      end

      results[name] = measurements(report)
    end
  end

  def destructive_results
    name = "#{DESTRUCTIVE_BENCHMARK} In Place"
    puts "Benchmarking: #{name}..."

    hash1, hash2 = BENCHMARKS.fetch(DESTRUCTIVE_BENCHMARK)

    { name => measurements(run_benchmark(hash1, hash2, DESTRUCTIVE_METHODS)) }
  end

  def measurements(report)
    report.entries.map { |entry| [entry.label, { ips: entry.ips, error: entry.error_percentage }] }.to_h
  end

  def run_benchmark(hash1, hash2, methods = NON_DESTRUCTIVE_METHODS)
    Benchmark.ips do |x|
      configure(x)

      methods.each do |lib_name, method|
        subject, other = fresh_inputs(hash1, hash2)

        x.report(label(lib_name, method)) { |times| LOOPS.public_send(method, subject, other, times) }
      end
    end
  end

  def run_benchmark_with_block(hash1, hash2, block, block_name)
    Benchmark.ips do |x|
      configure(x)

      NON_DESTRUCTIVE_METHODS.each do |lib_name, method|
        subject, other = fresh_inputs(hash1, hash2)

        x.report(label(lib_name, method, block_name)) do |times|
          LOOPS.public_send(:"#{method}_with_block", subject, other, times, block)
        end
      end
    end
  end

  # The name the library exposes rather than the alias the benchmark reaches it by, so each row reads as the method a reader would call.
  def label(lib_name, method, block_name = nil)
    public_name = method.to_s.sub(/\A(?:dm|sin|scratch)_/, '')
    return "#{lib_name} - #{public_name}" unless block_name

    "#{lib_name} - #{public_name} (#{block_name})"
  end

  def configure(job)
    job.warmup = WARMUP_SECONDS
    job.time = TIME_SECONDS
    job.quiet = true
  end

  # The destructive methods write into their receiver, so each report starts from a copy of its own rather than from whatever the report
  # before it left behind. Within its own report it does still merge into that same receiver from the second iteration on, which nothing
  # outside the timed loop can undo.
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
      warn_about_noise(test_name, results)
    end
  end

  def warn_about_noise(test_name, results)
    noisy = results.select { |_label, value| value[:error] > ERROR_PERCENTAGE_THRESHOLD }.sort_by { |_label, value| -value[:error] }
    return if noisy.empty?

    puts "Warning: #{test_name} was measured above ±#{ERROR_PERCENTAGE_THRESHOLD}%, so its ratios are not steady enough to publish:"
    noisy.each { |label, value| puts "  #{label} ±#{format('%.2f', value[:error])}%" }
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
    # Rows run fastest first, so the tie is the run from the top that ends at the first row the error cannot explain away. Asking each
    # row on its own instead would let a noisy row further down read as a tie and print Fastest under a row already marked slower,
    # which reads as an unsorted table.
    tied = sorted_results.take_while { |_key, value| indistinguishable?(fastest, value) }.length

    sorted_results.each_with_index.map do |(key, value), index|
      [key, format('%.1f', value[:ips]), format('±%.2f%%', value[:error]), speed_ratio(fastest, value, index < tied)]
    end
  end

  def speed_ratio(fastest, current, tied)
    return 'Fastest' if tied

    "#{(fastest[:ips] / current[:ips]).round(1)}x slower"
  end

  # Two entries are indistinguishable when the noise both were measured with leaves them unseparated. The flat 10% this replaces was a
  # guess that took no account of how steady either measurement actually was.
  def indistinguishable?(fastest, current)
    # A ratio that rounds to 1.0 reads as slower while saying the two ran at the same speed, so it is a tie on its own terms. It also
    # answers the fastest row, whose zero gap does not fall inside a zero-width band.
    return true if (fastest[:ips] / current[:ips]).round(1) <= 1.0

    overlapping_error_bands?(fastest, current)
  end

  # The bands are compared as iterations rather than as the two percentages, which are each a share of a different mean: adding them
  # would shrink the fastest row's half of the band by exactly the ratio being judged.
  def overlapping_error_bands?(fastest, current)
    current[:ips] * (1 + (current[:error] / 100)) > fastest[:ips] * (1 - (fastest[:error] / 100))
  end
end

DeepMergeBenchmark.run if __FILE__ == $PROGRAM_NAME
