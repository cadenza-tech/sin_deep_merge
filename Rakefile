# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'
require 'rubygems/package_task'

gemspec = Gem::Specification.load("#{__dir__}/sin_deep_merge.gemspec")

if RUBY_ENGINE == 'jruby'
  require 'rake/javaextensiontask'

  Rake::JavaExtensionTask.new('sin_deep_merge', gemspec) do |task|
    task.ext_dir = 'ext/java'
    task.source_version = '1.8'
    task.target_version = '1.8'
  end
else
  require 'rake/extensiontask'

  Rake::ExtensionTask.new('sin_deep_merge', gemspec) do |task|
    task.lib_dir = 'lib/sin_deep_merge'
  end
end

Gem::PackageTask.new(gemspec)

Rake::TestTask.new(:test) do |task|
  task.pattern = 'test/**/test_*.rb'
end

RuboCop::RakeTask.new(:rubocop) do |task|
  task.options = ['--format', ENV['RUBOCOP_FORMAT']] if ENV['RUBOCOP_FORMAT']
end

task benchmark: [:compile] do
  require_relative 'script/benchmark'

  sh 'ruby --yjit script/sin_deep_merge_benchmark.rb'
  sh 'ruby --yjit script/deep_merge_benchmark.rb'
  sh 'ruby --yjit script/activesupport_benchmark.rb'
  sh 'ruby --yjit script/scratch_benchmark.rb'
  Benchmark.summarize
end
