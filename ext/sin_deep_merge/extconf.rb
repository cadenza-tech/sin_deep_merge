# frozen_string_literal: true

require 'mkmf'

# rb_ext_ractor_safe() arrived in Ruby 3.0 and the gem still supports 2.3, so Init_sin_deep_merge guards its call on this.
have_func('rb_ext_ractor_safe')

create_makefile 'sin_deep_merge/sin_deep_merge'
