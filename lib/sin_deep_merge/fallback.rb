# frozen_string_literal: true

module SinDeepMerge
  # ActiveSupport's implementation, kept for Hash subclasses that override merge! or update, ActiveSupport's
  # HashWithIndifferentAccess being the common one. The extensions write straight into the storage of the hash, which skips such an
  # override, so they hand those receivers here instead. dup and merge! are called on the receiver so that its own overrides run.
  module Fallback
    module_function

    def deep_merge(hash, other_hash, &block)
      deep_merge!(hash.dup, other_hash, &block)
    end

    def deep_merge!(hash, other_hash, &block)
      hash.merge!(other_hash) do |key, this_val, other_val|
        if this_val.is_a?(Hash) && other_val.is_a?(Hash)
          this_val.deep_merge(other_val, &block)
        elsif block
          yield(key, this_val, other_val)
        else
          other_val
        end
      end
    end
  end
end
