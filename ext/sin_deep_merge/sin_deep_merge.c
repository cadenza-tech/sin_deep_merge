#include <ruby.h>

#if defined(HAVE_RUBY_STACK_CHECK) && defined(HAVE_RB_ESYSSTACKERROR)
#define DEEP_MERGE_STACK_GUARD
#endif

static ID id_call;

typedef struct {
  VALUE hash;
  VALUE block;
  int block_given;
} deep_merge_context;

static VALUE deep_merge_hashes(VALUE self, VALUE other, VALUE block);

static int deep_merge_iter(VALUE key, VALUE other_val, VALUE data) {
  deep_merge_context* ctx = (deep_merge_context*)data;
  VALUE current_val = rb_hash_lookup2(ctx->hash, key, Qundef);

  if (current_val == Qundef) {
    rb_hash_aset(ctx->hash, key, other_val);
  } else if (RB_TYPE_P(current_val, T_HASH) && RB_TYPE_P(other_val, T_HASH)) {
    /* Merge into a copy like ActiveSupport so shared or frozen nested hashes are never mutated. */
    VALUE merged = deep_merge_hashes(rb_obj_dup(current_val), other_val, ctx->block);
    rb_hash_aset(ctx->hash, key, merged);
  } else if (ctx->block_given) {
    VALUE args[3] = {key, current_val, other_val};
    /* rb_funcallv for TruffleRuby compat (Sulong lacks rb_proc_call_with_block) */
    VALUE result = rb_funcallv(ctx->block, id_call, 3, args);
    rb_hash_aset(ctx->hash, key, result);
  } else {
    rb_hash_aset(ctx->hash, key, other_val);
  }

  return ST_CONTINUE;
}

static VALUE deep_merge_hashes(VALUE self, VALUE other, VALUE block) {
#ifdef DEEP_MERGE_STACK_GUARD
  /* Raise while stack remains; overflowing the machine stack guard from C recursion can crash the process on a later overflow. */
  if (ruby_stack_check()) rb_raise(rb_eSysStackError, "stack level too deep");
#endif
  int block_given = !NIL_P(block);
  deep_merge_context ctx = {self, block, block_given};

  rb_hash_foreach(other, deep_merge_iter, (VALUE)&ctx);

  return self;
}

static VALUE hash_deep_merge_bang(int argc, VALUE* argv, VALUE self) {
  VALUE other;
  rb_scan_args(argc, argv, "1", &other);
  rb_check_frozen(self);
  other = rb_convert_type(other, T_HASH, "Hash", "to_hash");
  VALUE block = Qnil;
  if (rb_block_given_p()) {
    block = rb_block_proc();
  }

  deep_merge_hashes(self, other, block);

  return self;
}

static VALUE hash_deep_merge(int argc, VALUE* argv, VALUE self) {
  VALUE other;
  rb_scan_args(argc, argv, "1", &other);
  other = rb_convert_type(other, T_HASH, "Hash", "to_hash");
  VALUE block = Qnil;
  if (rb_block_given_p()) {
    block = rb_block_proc();
  }

  VALUE duplicated = rb_obj_dup(self);
  deep_merge_hashes(duplicated, other, block);

  return duplicated;
}

void Init_sin_deep_merge(void) {
  /*
   * Declaring this is a promise, and what backs it is that the only file-scope state is id_call, written in this function and read everywhere
   * else, and that every write lands on a hash the calling Ractor owns: deep_merge builds a dup and writes into that, and rb_check_frozen
   * keeps deep_merge! off a shareable receiver, which is frozen by definition. It has to run before the definitions, because what it marks is
   * whatever is defined after it.
   */
#ifdef HAVE_RB_EXT_RACTOR_SAFE
  rb_ext_ractor_safe(true);
#endif

  id_call = rb_intern("call");
  rb_define_method(rb_cHash, "deep_merge", RUBY_METHOD_FUNC(hash_deep_merge), -1);
  rb_define_method(rb_cHash, "deep_merge!", RUBY_METHOD_FUNC(hash_deep_merge_bang), -1);
}
