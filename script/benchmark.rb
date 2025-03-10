# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'terminal-table'
require_relative 'benchmarks'

class Benchmark
  def self.summarize # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    sin_deep_merge_benchmark_results_file_path = File.expand_path('../tmp/sin_deep_merge_benchmark_results.json', __dir__)
    deep_merge_benchmark_results_file_path = File.expand_path('../tmp/deep_merge_benchmark_results.json', __dir__)
    activesupport_benchmark_results_file_path = File.expand_path('../tmp/activesupport_benchmark_results.json', __dir__)
    scratch_benchmark_results_file_path = File.expand_path('../tmp/scratch_benchmark_results.json', __dir__)

    sin_deep_merge_benchmark_results = JSON.parse(File.read(sin_deep_merge_benchmark_results_file_path), symbolize_names: true)
    deep_merge_benchmark_results = JSON.parse(File.read(deep_merge_benchmark_results_file_path), symbolize_names: true)
    activesupport_benchmark_results = JSON.parse(File.read(activesupport_benchmark_results_file_path), symbolize_names: true)
    scratch_benchmark_results = JSON.parse(File.read(scratch_benchmark_results_file_path), symbolize_names: true)

    FileUtils.rm_f(sin_deep_merge_benchmark_results_file_path)
    FileUtils.rm_f(deep_merge_benchmark_results_file_path)
    FileUtils.rm_f(activesupport_benchmark_results_file_path)
    FileUtils.rm_f(scratch_benchmark_results_file_path)

    BENCHMARKS.each_key do |benchmark_name|
      results = sin_deep_merge_benchmark_results[benchmark_name]
                .merge(deep_merge_benchmark_results[benchmark_name])
                .merge(activesupport_benchmark_results[benchmark_name])
                .merge(scratch_benchmark_results[benchmark_name])
      rows = results.sort_by { |_key, value| value }.reverse.to_h
      rows = rows.map do |key, value|
        speed_ratio = rows.first[1] / value
        if speed_ratio - 1 >= 0.1
          slower_text = "#{speed_ratio.round(1)}x slower"
        else
          slower_text = '-'
        end
        [key, format('%.1f', value), slower_text]
      end

      table = Terminal::Table.new(
        title: "Benchmark Result (#{benchmark_name})",
        headings: ['Name', 'Iteration Per Second', 'Speed Ratio'],
        rows: rows
      )

      puts "\n#{table}"
    end
  end
end
