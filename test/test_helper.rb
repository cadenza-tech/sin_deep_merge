# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'minitest/autorun'
require 'minitest/pride'
require 'active_support/core_ext/hash/deep_merge'

class Hash
  alias_method :as_deep_merge, :deep_merge
  alias_method :as_deep_merge!, :deep_merge!
end
