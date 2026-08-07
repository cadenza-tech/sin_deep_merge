# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'minitest/autorun'
require 'minitest/pride'
require_relative 'ractor_test_helper'

# ActiveSupport's Hash#deep_merge and Hash#deep_merge!, copied because aliasing them is not enough: their recursion goes back through
# Hash#deep_merge, which SinDeepMerge overrides, so the comparison would end up checking SinDeepMerge against itself.
class Hash
  def as_deep_merge(other_hash, &block)
    dup.as_deep_merge!(other_hash, &block)
  end

  def as_deep_merge!(other_hash, &block)
    merge!(other_hash) do |key, this_val, other_val|
      if this_val.is_a?(Hash) && other_val.is_a?(Hash)
        this_val.as_deep_merge(other_val, &block)
      elsif block_given?
        yield(key, this_val, other_val)
      else
        other_val
      end
    end
  end
end
