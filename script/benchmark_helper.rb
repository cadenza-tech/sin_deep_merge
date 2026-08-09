# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'deep_merge'

class Hash
  alias_method :dm_deep_merge, :deep_merge
  alias_method :dm_deep_merge!, :deep_merge!

  undef_method :deep_merge
  undef_method :deep_merge!
end

require 'sin_deep_merge'

class Hash
  alias_method :sin_deep_merge, :deep_merge
  alias_method :sin_deep_merge!, :deep_merge!

  remove_method :deep_merge
  remove_method :deep_merge!
end

require 'active_support/core_ext/hash/deep_merge'

class Hash
  # Takes a block like the libraries it is measured against do, so that the block benchmarks give it the same work to do.
  def scratch_deep_merge(other_hash, &block)
    merged = dup
    other_hash.each do |key, value|
      current_value = merged[key]
      if current_value.is_a?(Hash) && value.is_a?(Hash)
        merged[key] = current_value.scratch_deep_merge(value, &block)
      elsif block && merged.key?(key)
        merged[key] = yield(key, current_value, value)
      else
        merged[key] = value
      end
    end
    merged
  end
end
