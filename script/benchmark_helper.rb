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
  def scratch_deep_merge(other_hash)
    merged = dup
    other_hash.each do |key, value|
      if merged[key].is_a?(Hash) && value.is_a?(Hash)
        merged[key] = merged[key].scratch_deep_merge(value)
      else
        merged[key] = value
      end
    end
    merged
  end
end
