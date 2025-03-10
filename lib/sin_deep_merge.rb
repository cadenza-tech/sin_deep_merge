# frozen_string_literal: true

class Hash
  # Explicitly undefine method before redefining to avoid Ruby warnings.
  undef_method(:deep_merge) if method_defined?(:deep_merge)
  undef_method(:deep_merge!) if method_defined?(:deep_merge!)
end

case RUBY_ENGINE
when 'jruby'
  require 'sin_deep_merge/sin_deep_merge.jar'

  JRuby::Util.load_ext('sin_deep_merge.SinDeepMergeLibrary')
else
  if RUBY_PLATFORM.include?('darwin')
    require 'sin_deep_merge/sin_deep_merge.bundle'
  else
    require 'sin_deep_merge/sin_deep_merge.so'
  end
end

require 'sin_deep_merge/version'
