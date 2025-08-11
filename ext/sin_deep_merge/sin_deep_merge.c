#include <ruby.h>

static ID id_call;
static ID id_to_hash;

typedef struct {
  VALUE hash;
  VALUE block;
  int destructive;
  int block_given;
} deep_merge_context;

static VALUE deep_merge_hashes(VALUE self, VALUE other, VALUE block, int destructive);

static int deep_merge_iter(VALUE key, VALUE other_val, VALUE data) {
  deep_merge_context *ctx = (deep_merge_context *)data;
  VALUE current_val = rb_hash_lookup2(ctx->hash, key, Qundef);

  if (current_val == Qundef) {
    rb_hash_aset(ctx->hash, key, other_val);
  } else if (RB_TYPE_P(current_val, T_HASH) && RB_TYPE_P(other_val, T_HASH)) {
    VALUE merged;
    if (ctx->destructive) {
      merged = deep_merge_hashes(current_val, other_val, ctx->block, 1);
    } else {
      merged = deep_merge_hashes(rb_obj_dup(current_val), other_val, ctx->block, 0);
    }
    rb_hash_aset(ctx->hash, key, merged);
  } else if (ctx->block_given) {
    VALUE args[3] = {key, current_val, other_val};
    VALUE result = rb_proc_call(ctx->block, rb_ary_new_from_values(3, args));
    rb_hash_aset(ctx->hash, key, result);
  } else {
    rb_hash_aset(ctx->hash, key, other_val);
  }

  return ST_CONTINUE;
}

static VALUE deep_merge_hashes(VALUE self, VALUE other, VALUE block, int destructive) {
  int block_given = !NIL_P(block);
  deep_merge_context ctx = {self, block, destructive, block_given};

  rb_hash_foreach(other, deep_merge_iter, (VALUE)&ctx);

  return self;
}

static VALUE hash_deep_merge_bang(int argc, VALUE *argv, VALUE self) {
  VALUE other;
  rb_scan_args(argc, argv, "1", &other);
  other = rb_funcall(other, id_to_hash, 0);
  VALUE block = Qnil;
  if (rb_block_given_p()) {
    block = rb_block_proc();
  }

  deep_merge_hashes(self, other, block, 1);

  return self;
}

static VALUE hash_deep_merge(int argc, VALUE *argv, VALUE self) {
  VALUE other;
  rb_scan_args(argc, argv, "1", &other);
  other = rb_funcall(other, id_to_hash, 0);
  VALUE block = Qnil;
  if (rb_block_given_p()) {
    block = rb_block_proc();
  }

  VALUE duplicated = rb_obj_dup(self);
  deep_merge_hashes(duplicated, other, block, 0);

  return duplicated;
}

void Init_sin_deep_merge(void) {
  id_call = rb_intern("call");
  id_to_hash = rb_intern("to_hash");
  rb_define_method(rb_cHash, "deep_merge", RUBY_METHOD_FUNC(hash_deep_merge), -1);
  rb_define_method(rb_cHash, "deep_merge!", RUBY_METHOD_FUNC(hash_deep_merge_bang), -1);
}
