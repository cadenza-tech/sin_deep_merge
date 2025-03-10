#include <ruby.h>

typedef struct {
  VALUE hash;
  VALUE block;
} deep_merge_context;

static VALUE deep_merge_hashes(VALUE self, VALUE other, VALUE block);

static int deep_merge_iter(VALUE key, VALUE other_val, VALUE data) {
  deep_merge_context *ctx = (deep_merge_context *)data;
  VALUE current_val = rb_hash_lookup2(ctx->hash, key, Qundef);

  if (current_val == Qundef) {
    rb_hash_aset(ctx->hash, key, other_val);
  } else if (RB_TYPE_P(current_val, T_HASH) && RB_TYPE_P(other_val, T_HASH)) {
    VALUE merged = deep_merge_hashes(rb_obj_dup(current_val), other_val, ctx->block);
    rb_hash_aset(ctx->hash, key, merged);
  } else if (!NIL_P(ctx->block)) {
    VALUE result = rb_funcall(ctx->block, rb_intern("call"), 3, key, current_val, other_val);
    rb_hash_aset(ctx->hash, key, result);
  } else {
    rb_hash_aset(ctx->hash, key, other_val);
  }

  return ST_CONTINUE;
}

static VALUE deep_merge_hashes(VALUE self, VALUE other, VALUE block) {
  deep_merge_context ctx = {self, block};

  rb_hash_foreach(other, deep_merge_iter, (VALUE)&ctx);

  return self;
}

static VALUE hash_deep_merge_bang(int argc, VALUE *argv, VALUE self) {
  VALUE other;
  rb_scan_args(argc, argv, "1", &other);
  other = rb_funcall(other, rb_intern("to_hash"), 0);
  VALUE block = Qnil;
  if (rb_block_given_p()) {
    block = rb_block_proc();
  }

  deep_merge_hashes(self, other, block);

  return self;
}

static VALUE hash_deep_merge(int argc, VALUE *argv, VALUE self) {
  return hash_deep_merge_bang(argc, argv, rb_obj_dup(self));
}

void Init_sin_deep_merge(void) {
  rb_define_method(rb_cHash, "deep_merge", RUBY_METHOD_FUNC(hash_deep_merge), -1);
  rb_define_method(rb_cHash, "deep_merge!", RUBY_METHOD_FUNC(hash_deep_merge_bang), -1);
}
