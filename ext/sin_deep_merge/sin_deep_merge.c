#include <ruby.h>

#if defined(HAVE_RUBY_STACK_CHECK) && defined(HAVE_RB_ESYSSTACKERROR)
#define DEEP_MERGE_STACK_GUARD
#endif

typedef struct {
  VALUE hash;
  int block_given;
} deep_merge_context;

static VALUE deep_merge_hashes(VALUE self, VALUE other, int block_given);

/*
 * A Hash subclass may override merge! or update to police what gets stored, as ActiveSupport's HashWithIndifferentAccess does to keep its
 * keys strings. rb_hash_aset writes past that override, so those receivers go to SinDeepMerge::Fallback, which is ActiveSupport's own
 * implementation and therefore reaches the override through merge!. rb_obj_class sees through a singleton class, so a plain hash carrying
 * singleton methods still takes the fast path.
 */
static int plain_hash_p(VALUE hash) { return rb_obj_class(hash) == rb_cHash; }

static VALUE deep_merge_forward(VALUE recv, ID mid, int argc, const VALUE* argv) {
  if (!rb_block_given_p()) return rb_funcallv(recv, mid, argc, argv);

  /* rb_funcall_passing_block would spare the Proc, but Sulong lacks it up to TruffleRuby 22.3. */
  return rb_funcall_with_block(recv, mid, argc, argv, rb_block_proc());
}

static VALUE deep_merge_fallback(VALUE self, VALUE other, const char* name) {
  VALUE args[2] = {self, other};

  return deep_merge_forward(rb_path2class("SinDeepMerge::Fallback"), rb_intern(name), 2, args);
}

static int deep_merge_iter(VALUE key, VALUE other_val, VALUE data) {
  deep_merge_context* ctx = (deep_merge_context*)data;
  VALUE current_val = rb_hash_lookup2(ctx->hash, key, Qundef);
  VALUE new_val = other_val;

  /* An absent key takes other_val as is, which is what new_val already holds. */
  if (current_val != Qundef) {
    if (RB_TYPE_P(current_val, T_HASH) && RB_TYPE_P(other_val, T_HASH)) {
      /* Merge into a copy like ActiveSupport so shared or frozen nested hashes are never mutated. */
      new_val = plain_hash_p(current_val)
                    ? deep_merge_hashes(rb_obj_dup(current_val), other_val, ctx->block_given)
                    /* ActiveSupport recurses as this_val.deep_merge(other_val), so a nested subclass gets its own override too. */
                    : deep_merge_forward(current_val, rb_intern("deep_merge"), 1, &other_val);
    } else if (ctx->block_given) {
      /* Yield directly: no Proc to allocate, and it avoids rb_proc_call_with_block, which Sulong lacks up to TruffleRuby 23.0. */
      new_val = rb_yield_values(3, key, current_val, other_val);
    }
  }

  rb_hash_aset(ctx->hash, key, new_val);

  return ST_CONTINUE;
}

static VALUE deep_merge_hashes(VALUE self, VALUE other, int block_given) {
  deep_merge_context ctx = {self, block_given};

#ifdef DEEP_MERGE_STACK_GUARD
  /* Raise while stack remains; overflowing the machine stack guard from C recursion can crash the process on a later overflow. */
  if (ruby_stack_check()) rb_raise(rb_eSysStackError, "stack level too deep");
#endif

  rb_hash_foreach(other, deep_merge_iter, (VALUE)&ctx);

  return self;
}

static VALUE hash_deep_merge_bang(VALUE self, VALUE other) {
  /* Hand over before converting other: a subclass may treat a Hash and a to_hash convertible differently, as merge! is free to. */
  if (!plain_hash_p(self)) return deep_merge_fallback(self, other, "deep_merge!");

  rb_check_frozen(self);
  other = rb_convert_type(other, T_HASH, "Hash", "to_hash");

  return deep_merge_hashes(self, other, rb_block_given_p());
}

static VALUE hash_deep_merge(VALUE self, VALUE other) {
  if (!plain_hash_p(self)) return deep_merge_fallback(self, other, "deep_merge");

  other = rb_convert_type(other, T_HASH, "Hash", "to_hash");

  return deep_merge_hashes(rb_obj_dup(self), other, rb_block_given_p());
}

void Init_sin_deep_merge(void) {
  /*
   * Declaring this is a promise, and what backs it is that there is no file-scope state at all, and that every write lands on a hash the
   * calling Ractor owns: deep_merge builds a dup and writes into that, and deep_merge! is kept off a shareable receiver, which is frozen by
   * definition, either by rb_check_frozen or by the frozen check merge! runs on the subclass path. The only thing reached for outside the
   * arguments is the SinDeepMerge::Fallback constant, and a module is shareable. It has to run before the definitions, because what it marks
   * is whatever is defined after it.
   */
#ifdef HAVE_RB_EXT_RACTOR_SAFE
  rb_ext_ractor_safe(true);
#endif

  rb_define_method(rb_cHash, "deep_merge", RUBY_METHOD_FUNC(hash_deep_merge), 1);
  rb_define_method(rb_cHash, "deep_merge!", RUBY_METHOD_FUNC(hash_deep_merge_bang), 1);
}
