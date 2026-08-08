# frozen_string_literal: true

require_relative 'test_helper'
require 'sin_deep_merge'

class TestDeepMergeSubclass < Minitest::Test
  # A stand-in for ActiveSupport's HashWithIndifferentAccess: what keeps the keys strings is the merge! override, so an implementation that
  # writes into the hash directly instead of going through merge! leaves symbol keys behind.
  class StringKeyHash < Hash
    def merge!(other_hash)
      other_hash.to_hash.each_pair do |key, value|
        value = yield(key.to_s, self[key.to_s], value) if block_given? && key?(key.to_s)
        self[key.to_s] = value
      end
      self
    end

    alias_method :update, :merge!
  end

  def test_merge
    hash1 = build('a' => build('b' => 1))
    hash2 = { a: { c: 2 }, d: 3 }

    merged = hash1.deep_merge(hash2)

    assert_equal({ 'a' => { 'b' => 1, 'c' => 2 }, 'd' => 3 }, merged)
    assert_instance_of(StringKeyHash, merged)
    assert_instance_of(StringKeyHash, merged['a'])
    assert_equal({ 'a' => { 'b' => 1 } }, hash1)
  end

  def test_merge_bang
    nested = build('b' => 1)
    hash1 = build('a' => nested)
    hash2 = { a: { c: 2 }, d: 3 }

    merged = hash1.deep_merge!(hash2)

    assert_equal({ 'a' => { 'b' => 1, 'c' => 2 }, 'd' => 3 }, merged)
    assert_same(hash1, merged)
    assert_instance_of(StringKeyHash, merged['a'])
    assert_equal({ 'b' => 1 }, nested)
  end

  def test_nested_in_plain_hash
    nested = build('b' => 1)
    hash1 = { a: nested }
    hash2 = { a: { b: 2, c: 3 } }

    merged = hash1.deep_merge(hash2) { |_key, old_val, new_val| old_val + new_val }

    assert_equal({ a: { 'b' => 3, 'c' => 3 } }, merged)
    assert_instance_of(StringKeyHash, merged[:a])
    assert_equal({ 'b' => 1 }, nested)
  end

  def test_nested_in_plain_hash_bang
    nested = build('b' => 1)
    hash1 = { a: nested }
    hash2 = { a: { b: 2, c: 3 } }

    hash1.deep_merge!(hash2) { |_key, old_val, new_val| old_val + new_val }

    assert_equal({ a: { 'b' => 3, 'c' => 3 } }, hash1)
    assert_equal({ 'b' => 1 }, nested)
  end

  def test_frozen_hash
    hash1 = build('a' => 1).freeze

    if defined?(FrozenError)
      assert_raises(FrozenError) { hash1.deep_merge!(b: 2) }
    else
      assert_raises(RuntimeError) { hash1.deep_merge!(b: 2) }
    end
  end

  def test_compatibility
    hash1 = build('a' => build('b' => 1))
    hash2 = { a: { b: 2, c: 3 }, d: 4 }

    expected = hash1.as_deep_merge(hash2) { |_key, old_val, new_val| old_val + new_val }

    assert_equal(expected, hash1.deep_merge(hash2) { |_key, old_val, new_val| old_val + new_val })
  end

  def test_compatibility_bang
    hash1 = build('a' => build('b' => 1))
    hash1_dup = build('a' => build('b' => 1))
    hash2 = { a: { b: 2, c: 3 }, d: 4 }

    expected = hash1_dup.as_deep_merge!(hash2) { |_key, old_val, new_val| old_val + new_val }

    assert_equal(expected, hash1.deep_merge!(hash2) { |_key, old_val, new_val| old_val + new_val })
  end

  # The extensions reach SinDeepMerge::Fallback by looking the constant up by name, which is the one thing on this path that a
  # non-main Ractor could refuse. The plain Hash tests never take it, so nothing else here would notice.
  def test_inside_ractor
    expected = [{ 'a' => { 'b' => 1, 'c' => 2 }, 'd' => 3 }, { 'a' => 1, 'b' => 2 }]

    assert_equal(
      expected,
      in_ractor do
        hash = StringKeyHash.new
        hash['a'] = StringKeyHash.new
        hash['a']['b'] = 1

        destructive = StringKeyHash.new
        destructive['a'] = 1

        [hash.deep_merge(a: { c: 2 }, d: 3), destructive.deep_merge!(b: 2)]
      end
    )
  end

  private

  def build(pairs)
    pairs.each_with_object(StringKeyHash.new) { |(key, value), hash| hash[key] = value }
  end
end
