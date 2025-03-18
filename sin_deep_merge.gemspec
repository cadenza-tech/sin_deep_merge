# frozen_string_literal: true

require_relative 'lib/sin_deep_merge/version'

Gem::Specification.new do |spec|
  spec.name = 'sin_deep_merge'
  spec.version = SinDeepMerge::VERSION
  spec.description = 'Merge deeply nested hashes faster than DeepMerge or ActiveSupport'
  spec.summary = 'Merge deeply nested hashes faster than DeepMerge or ActiveSupport'
  spec.authors = ['Masahiro']
  spec.email = ['watanabe@cadenza-tech.com']
  spec.license = 'MIT'

  github_root_uri = 'https://github.com/cadenza-tech/sin_deep_merge'
  spec.homepage = "#{github_root_uri}/tree/v#{spec.version}"
  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => spec.homepage,
    'changelog_uri' => "#{github_root_uri}/blob/v#{spec.version}/CHANGELOG.md",
    'bug_tracker_uri' => "#{github_root_uri}/issues",
    'documentation_uri' => "https://rubydoc.info/gems/#{spec.name}/#{spec.version}",
    'funding_uri' => 'https://patreon.com/CadenzaTech',
    'rubygems_mfa_required' => 'true'
  }

  spec.required_ruby_version = '>= 2.3.0'

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files]) do |ls|
    ls.readlines("\x0").map { |f| f.chomp("\x0") }.reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ ext/ script/ test/ spec/ features/ .git .github .editorconfig .rubocop.yml appveyor CODE_OF_CONDUCT.md Gemfile]) ||
        Dir['lib/**/*.jar'].include?(f)
    end
  end

  if RUBY_ENGINE == 'jruby'
    spec.platform = 'java'
    spec.files += Dir['lib/**/*.jar'] + Dir['ext/**/*.java']
  else
    spec.platform = Gem::Platform::RUBY # rubocop:disable Gemspec/DuplicatedAssignment
    spec.files += ['ext/sin_deep_merge/sin_deep_merge.c', 'ext/sin_deep_merge/extconf.rb']
    spec.extensions = ['ext/sin_deep_merge/extconf.rb']
  end

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
