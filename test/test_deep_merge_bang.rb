# frozen_string_literal: true

require_relative 'test_helper'
require 'sin_deep_merge'

class TestDeepMergeBang < Minitest::Test
  def test_merge
    hash1 = { a: 1, b: 'string', c: :symbol, d: true, e: [2, 3], f: { g: 4 }, h: nil }
    hash2 = { i: 5, j: 'string', k: :symbol, l: false, m: [6, 7], n: { o: 8 }, p: nil }

    expected = { a: 1, b: 'string', c: :symbol, d: true, e: [2, 3], f: { g: 4 }, h: nil, i: 5, j: 'string', k: :symbol, l: false, m: [6, 7], n: { o: 8 }, p: nil } # rubocop:disable Layout/LineLength

    assert_equal(expected, hash1.deep_merge!(hash2))
    assert_equal(expected, hash1)
  end

  def test_overwrite
    hash1 = { a: 1, b: 'string', c: :symbol, d: true, e: [2, 3], f: { g: 4 }, h: nil }
    hash2 = { a: 2, b: 'new_string', c: :new_symbol, d: false, e: [3, 4], f: { g: 5 }, h: 'new' }

    expected = { a: 2, b: 'new_string', c: :new_symbol, d: false, e: [3, 4], f: { g: 5 }, h: 'new' }

    assert_equal(expected, hash1.deep_merge!(hash2))
    assert_equal(expected, hash1)
  end

  def test_recursive
    hash1 = { a: { b: { c: 1, d: 2 } } }
    hash2 = { a: { b: { d: 3, e: 4 } } }

    expected = { a: { b: { c: 1, d: 3, e: 4 } } }

    assert_equal(expected, hash1.deep_merge!(hash2))
    assert_equal(expected, hash1)
  end

  def test_deep_recursive
    hash1 = { a: { b: { c: { d: { e: { f: { g: { h: { i: { j: { k: { l: { m: { n: { o: { p: { q: { r: { s: { t: { u: { v: { w: { x: { y: { z: 1, zz: 2 } } } } } } } } } } } } } } } } } } } } } } } } } } # rubocop:disable Layout/LineLength
    hash2 = { a: { b: { c: { d: { e: { f: { g: { h: { i: { j: { k: { l: { m: { n: { o: { p: { q: { r: { s: { t: { u: { v: { w: { x: { y: { zz: 3, zzz: 4 } } } } } } } } } } } } } } } } } } } } } } } } } } # rubocop:disable Layout/LineLength

    expected = { a: { b: { c: { d: { e: { f: { g: { h: { i: { j: { k: { l: { m: { n: { o: { p: { q: { r: { s: { t: { u: { v: { w: { x: { y: { z: 1, zz: 3, zzz: 4 } } } } } } } } } } } } } } } } } } } } } } } } } } # rubocop:disable Layout/LineLength

    assert_equal(expected, hash1.deep_merge!(hash2))
    assert_equal(expected, hash1)
  end

  def test_string_and_symbol_keys
    hash1 = { 'a' => 1 }
    hash2 = { a: 2 }

    expected = { 'a' => 1, :a => 2 }

    assert_equal(expected, hash1.deep_merge!(hash2))
    assert_equal(expected, hash1)
  end

  def test_with_block
    hash1 = { a: 1, b: 2 }
    hash2 = { b: 3, c: 4 }

    expected = { a: 1, b: 5, c: 4 }

    assert_equal(expected, hash1.deep_merge!(hash2) { |_key, old_val, new_val| old_val + new_val })
    assert_equal(expected, hash1)

    hash1 = { a: 1, b: 2 }

    assert_equal(
      expected,
      hash1.deep_merge!(hash2) do |_key, old_val, new_val|
        old_val + new_val
      end
    )
    assert_equal(expected, hash1)
  end

  def test_with_proc
    hash1 = { a: 1, b: 2 }
    hash2 = { b: 3, c: 4 }
    merge_proc = proc { |_key, old_val, new_val| old_val + new_val }

    expected = { a: 1, b: 5, c: 4 }

    assert_equal(expected, hash1.deep_merge!(hash2, &merge_proc))
    assert_equal(expected, hash1)
  end

  def test_compatibility
    hash1 = { a: 1, b: 2, c: [3, 4], d: { e: 5 }, f: { g: { h: 6, i: 7 } } }
    hash1_dup = Marshal.load(Marshal.dump(hash1))
    hash2 = { b: 3, c: [4, 5], d: { f: 6 }, f: { g: { i: 8 } } }

    expected = hash1_dup.as_deep_merge!(hash2)

    assert_equal(expected, hash1.deep_merge!(hash2))
    assert_equal(hash1_dup, hash1)
  end

  def test_compatibility_with_block
    hash1 = { a: 1, b: 2 }
    hash1_dup = Marshal.load(Marshal.dump(hash1))
    hash2 = { b: 3, c: 4 }

    expected = hash1_dup.as_deep_merge!(hash2) { |_key, old_val, new_val| old_val + new_val }

    assert_equal(expected, hash1.deep_merge!(hash2) { |_key, old_val, new_val| old_val + new_val })
    assert_equal(hash1_dup, hash1)

    hash1 = { a: 1, b: 2 }

    assert_equal(
      expected,
      hash1.deep_merge!(hash2) do |_key, old_val, new_val|
        old_val + new_val
      end
    )
    assert_equal(hash1_dup, hash1)
  end

  def test_compatibility_with_proc
    hash1 = { a: 1, b: 2 }
    hash1_dup = Marshal.load(Marshal.dump(hash1))
    hash2 = { b: 3, c: 4 }
    merge_proc = proc { |_key, old_val, new_val| old_val + new_val }

    expected = hash1_dup.as_deep_merge!(hash2, &merge_proc)

    assert_equal(expected, hash1.deep_merge!(hash2, &merge_proc))
    assert_equal(hash1_dup, hash1)
  end
end
