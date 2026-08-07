# frozen_string_literal: true

require_relative 'test_helper'
require 'sin_deep_merge'

class TestDeepMerge < Minitest::Test
  def test_merge
    hash1 = { a: 1, b: 'string', c: :symbol, d: true, e: [2, 3], f: { g: 4 }, h: nil }
    hash2 = { i: 5, j: 'string', k: :symbol, l: false, m: [6, 7], n: { o: 8 }, p: nil }

    expected = { a: 1, b: 'string', c: :symbol, d: true, e: [2, 3], f: { g: 4 }, h: nil, i: 5, j: 'string', k: :symbol, l: false, m: [6, 7], n: { o: 8 }, p: nil } # rubocop:disable Layout/LineLength

    assert_equal(expected, hash1.deep_merge(hash2))
  end

  def test_overwrite
    hash1 = { a: 1, b: 'string', c: :symbol, d: true, e: [2, 3], f: { g: 4 }, h: nil }
    hash2 = { a: 2, b: 'new_string', c: :new_symbol, d: false, e: [3, 4], f: { g: 5 }, h: 'new' }

    expected = { a: 2, b: 'new_string', c: :new_symbol, d: false, e: [3, 4], f: { g: 5 }, h: 'new' }

    assert_equal(expected, hash1.deep_merge(hash2))
  end

  def test_recursive
    hash1 = { a: { b: { c: 1, d: 2 } } }
    hash2 = { a: { b: { d: 3, e: 4 } } }

    expected = { a: { b: { c: 1, d: 3, e: 4 } } }

    assert_equal(expected, hash1.deep_merge(hash2))
  end

  def test_deep_recursive
    hash1 = { a: { b: { c: { d: { e: { f: { g: { h: { i: { j: { k: { l: { m: { n: { o: { p: { q: { r: { s: { t: { u: { v: { w: { x: { y: { z: 1, zz: 2 } } } } } } } } } } } } } } } } } } } } } } } } } } # rubocop:disable Layout/LineLength
    hash2 = { a: { b: { c: { d: { e: { f: { g: { h: { i: { j: { k: { l: { m: { n: { o: { p: { q: { r: { s: { t: { u: { v: { w: { x: { y: { zz: 3, zzz: 4 } } } } } } } } } } } } } } } } } } } } } } } } } } # rubocop:disable Layout/LineLength

    expected = { a: { b: { c: { d: { e: { f: { g: { h: { i: { j: { k: { l: { m: { n: { o: { p: { q: { r: { s: { t: { u: { v: { w: { x: { y: { z: 1, zz: 3, zzz: 4 } } } } } } } } } } } } } } } } } } } } } } } } } } # rubocop:disable Layout/LineLength

    assert_equal(expected, hash1.deep_merge(hash2))
  end

  def test_string_and_symbol_keys
    hash1 = { 'a' => 1 }
    hash2 = { a: 2 }

    expected = { 'a' => 1, :a => 2 }

    assert_equal(expected, hash1.deep_merge(hash2))
  end

  def test_string_keys
    hash1 = { 'a' => 1, 'b' => { 'c' => 2 } }
    hash2 = { 'b' => { 'd' => 3 }, 'e' => 4 }

    expected = { 'a' => 1, 'b' => { 'c' => 2, 'd' => 3 }, 'e' => 4 }

    assert_equal(expected, hash1.deep_merge(hash2))
  end

  def test_integer_keys
    hash1 = { 1 => { 2 => 3 } }
    hash2 = { 1 => { 4 => 5 }, 6 => 7 }

    expected = { 1 => { 2 => 3, 4 => 5 }, 6 => 7 }

    assert_equal(expected, hash1.deep_merge(hash2))
  end

  def test_with_block
    hash1 = { a: 1, b: 2 }
    hash2 = { b: 3, c: 4 }

    expected = { a: 1, b: 5, c: 4 }

    assert_equal(expected, hash1.deep_merge(hash2) { |_key, old_val, new_val| old_val + new_val })
    assert_equal(
      expected,
      hash1.deep_merge(hash2) do |_key, old_val, new_val|
        old_val + new_val
      end
    )
  end

  def test_with_proc
    hash1 = { a: 1, b: 2 }
    hash2 = { b: 3, c: 4 }
    merge_proc = proc { |_key, old_val, new_val| old_val + new_val }

    expected = { a: 1, b: 5, c: 4 }

    assert_equal(expected, hash1.deep_merge(hash2, &merge_proc))
  end

  def test_with_lambda
    hash1 = { a: 1, b: 2 }
    hash2 = { b: 3, c: 4 }
    merge_lambda = lambda { |_key, old_val, new_val| old_val + new_val } # rubocop:disable Style/Lambda

    expected = { a: 1, b: 5, c: 4 }

    assert_equal(expected, hash1.deep_merge(hash2, &merge_lambda))
  end

  def test_non_destructive
    hash1 = { a: { b: 1 } }
    hash2 = { a: { c: 2 } }

    expected = Marshal.load(Marshal.dump(hash1))

    hash1.deep_merge(hash2)

    assert_equal(expected, hash1)
  end

  def test_does_not_mutate_nested_hashes_of_self
    nested = { b: 1 }
    hash1 = { a: nested }
    hash2 = { a: { c: 2 } }

    hash1.deep_merge(hash2)

    assert_equal({ b: 1 }, nested)
    assert_same(nested, hash1[:a])
  end

  def test_with_object_responding_to_to_hash
    other = Object.new
    def other.to_hash
      { b: 2 }
    end

    assert_equal({ a: 1, b: 2 }, { a: 1 }.deep_merge(other))
  end

  def test_with_non_hash_argument
    assert_raises(TypeError) { { a: 1 }.deep_merge(nil) }
    assert_raises(TypeError) { { a: 1 }.deep_merge(1) }
  end

  def test_deeply_nested_hashes_raise_system_stack_error
    # CRuby 2.4 and older still take the process down on the second overflow, and no other engine compiles the C guard in.
    skip('CRuby 2.5+ only') unless RUBY_ENGINE == 'ruby' && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.5')

    2.times do
      hash1 = { a: 1 }
      hash2 = { a: 1 }
      100_000.times do
        hash1 = { n: hash1 }
        hash2 = { n: hash2 }
      end

      assert_raises(SystemStackError) { hash1.deep_merge(hash2) }
    end
  end

  def test_compatibility
    hash1 = { a: 1, b: 2, c: [3, 4], d: { e: 5 }, f: { g: { h: 6, i: 7 } } }
    hash2 = { b: 3, c: [4, 5], d: { f: 6 }, f: { g: { i: 8 } } }

    expected = hash1.as_deep_merge(hash2)

    assert_equal(expected, hash1.deep_merge(hash2))
  end

  def test_compatibility_with_block
    hash1 = { a: 1, b: 2 }
    hash2 = { b: 3, c: 4 }

    expected = hash1.as_deep_merge(hash2) { |_key, old_val, new_val| old_val + new_val }

    assert_equal(expected, hash1.deep_merge(hash2) { |_key, old_val, new_val| old_val + new_val })
    assert_equal(
      expected,
      hash1.deep_merge(hash2) do |_key, old_val, new_val|
        old_val + new_val
      end
    )
  end

  def test_compatibility_with_proc
    hash1 = { a: 1, b: 2 }
    hash2 = { b: 3, c: 4 }
    merge_proc = proc { |_key, old_val, new_val| old_val + new_val }

    expected = hash1.as_deep_merge(hash2, &merge_proc)

    assert_equal(expected, hash1.deep_merge(hash2, &merge_proc))
  end

  def test_compatibility_with_lambda
    hash1 = { a: 1, b: 2 }
    hash2 = { b: 3, c: 4 }
    merge_lambda = lambda { |_key, old_val, new_val| old_val + new_val } # rubocop:disable Style/Lambda

    expected = hash1.as_deep_merge(hash2, &merge_lambda)

    assert_equal(expected, hash1.deep_merge(hash2, &merge_lambda))
  end

  def test_inside_ractor
    expected = { a: { b: 1, c: 4, e: 5 }, d: 3, f: 6 }

    assert_equal(expected, in_ractor { { a: { b: 1, c: 2 }, d: 3 }.deep_merge({ a: { c: 4, e: 5 }, f: 6 }) })
  end
end
