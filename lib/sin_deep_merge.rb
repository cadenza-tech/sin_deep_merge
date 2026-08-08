# frozen_string_literal: true

class Hash
  # Explicitly undefine method before redefining to avoid Ruby warnings.
  undef_method(:deep_merge) if method_defined?(:deep_merge)
  undef_method(:deep_merge!) if method_defined?(:deep_merge!)
end

# Both extensions look this up by name when they meet a Hash subclass, so it has to be in place before they can be called.
require 'sin_deep_merge/fallback'

case RUBY_ENGINE
when 'jruby'
  require 'jruby'
  require 'sin_deep_merge/sin_deep_merge.jar'

  Java::sin_deep_merge::SinDeepMergeLibrary.new.load(JRuby.runtime, false)
else
  # The extension-less require lets Ruby resolve the platform-specific shared library suffix (.bundle on macOS, .so elsewhere) via DLEXT.
  require 'sin_deep_merge/sin_deep_merge'
end

require 'sin_deep_merge/version'
