# frozen_string_literal: true

require 'mkmf'

# rb_ext_ractor_safe() arrived in Ruby 3.0 and the gem still supports 2.3, so Init_sin_deep_merge guards its call on this.
have_func('rb_ext_ractor_safe')
# TruffleRuby has no ruby_stack_check(), so deep_merge_hashes guards its stack check on this.
have_func('ruby_stack_check')
have_var('rb_eSysStackError', 'ruby.h')
# rb_hash_dup() skips the initialize_dup dispatch rb_obj_dup() pays for, and DEEP_MERGE_HASH_DUP falls back to the latter without it.
have_func('rb_hash_dup')

create_makefile 'sin_deep_merge/sin_deep_merge'
