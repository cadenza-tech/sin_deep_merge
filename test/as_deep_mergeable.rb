# frozen_string_literal: true

# ActiveSupport::DeepMergeable as of activesupport 8.1, copied rather than aliased: ActiveSupport's own deep_merge recurses through
# Hash#deep_merge!, which SinDeepMerge overrides, so an alias would end up comparing SinDeepMerge against itself. What decides whether
# to recurse is the deep_merge? hook rather than a plain Hash check, and the module shape is kept so that a drift shows up here.
module AsDeepMergeable
  def as_deep_merge(other, &block)
    dup.as_deep_merge!(other, &block)
  end

  def as_deep_merge!(other, &block)
    merge!(other) do |key, this_val, other_val|
      if this_val.is_a?(AsDeepMergeable) && this_val.deep_merge?(other_val)
        this_val.as_deep_merge(other_val, &block)
      elsif block
        yield(key, this_val, other_val)
      else
        other_val
      end
    end
  end

  def deep_merge?(other)
    other.is_a?(self.class)
  end
end
