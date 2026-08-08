# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('../lib', __dir__))

require 'minitest/autorun'
require 'minitest/pride'
require_relative 'as_deep_mergeable'
require_relative 'ractor_test_helper'

# What ActiveSupport itself does to Hash: it includes the module and widens deep_merge? from the module default of self.class to any Hash.
class Hash
  include AsDeepMergeable

  def deep_merge?(other)
    other.is_a?(Hash)
  end
end
