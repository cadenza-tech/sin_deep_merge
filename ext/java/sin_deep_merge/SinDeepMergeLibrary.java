package sin_deep_merge;

import org.jruby.Ruby;
import org.jruby.RubyHash;
import org.jruby.RubyModule;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.Helpers;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.Library;

public class SinDeepMergeLibrary implements Library {
    @Override
    public void load(Ruby runtime, boolean wrap) {
        runtime.getHash().defineAnnotatedMethods(SinDeepMergeLibrary.class);
    }

    @JRubyMethod(name = "deep_merge", required = 1)
    public static IRubyObject deepMerge(
            ThreadContext context, IRubyObject self, IRubyObject other, Block block) {
        if (!isPlainHash(context, self)) {
            return fallback(context, "deep_merge", self, other, block);
        }
        RubyHash otherHash = other.convertToHash();
        RubyHash dupedHash = (RubyHash) ((RubyHash) self).dup();
        deepMergeInto(context, otherHash, dupedHash, block);
        return dupedHash;
    }

    @JRubyMethod(name = "deep_merge!", required = 1)
    public static IRubyObject deepMergeBang(
            ThreadContext context, IRubyObject self, IRubyObject other, Block block) {
        // Hand over before converting other: a subclass may treat a Hash and a to_hash convertible
        // differently, as merge! is free to.
        if (!isPlainHash(context, self)) {
            return fallback(context, "deep_merge!", self, other, block);
        }
        RubyHash selfHash = (RubyHash) self;
        selfHash.modify();
        RubyHash otherHash = other.convertToHash();
        deepMergeInto(context, otherHash, selfHash, block);
        return selfHash;
    }

    // A Hash subclass may override merge! or update to police what gets stored, as ActiveSupport's
    // HashWithIndifferentAccess does to keep its keys strings. op_aset writes past that override,
    // so those receivers go to SinDeepMerge::Fallback, ActiveSupport's own implementation, which
    // does reach the override through merge!. getRealClass sees through a singleton class, so a
    // plain hash carrying singleton methods still takes the fast path.
    private static boolean isPlainHash(ThreadContext context, IRubyObject object) {
        return object.getMetaClass().getRealClass() == context.runtime.getHash();
    }

    private static IRubyObject fallback(
            ThreadContext context, String name, IRubyObject self, IRubyObject other, Block block) {
        RubyModule sinDeepMerge = context.runtime.getModule("SinDeepMerge");
        IRubyObject target = sinDeepMerge.getConstant("Fallback");
        return Helpers.invoke(context, target, name, new IRubyObject[] {self, other}, block);
    }

    private static void deepMergeInto(
            ThreadContext context, RubyHash other, RubyHash target, Block block) {
        try {
            other.visitAll(context, new DeepMergeVisitor(block), target);
        } catch (StackOverflowError e) {
            // Match the C extension, which raises SystemStackError rather than letting the machine
            // stack overflow escape as is.
            throw context.runtime.newSystemStackError("stack level too deep", e);
        }
    }

    private static class DeepMergeVisitor extends RubyHash.VisitorWithState<RubyHash> {
        private final Block block;

        DeepMergeVisitor(Block block) {
            this.block = block;
        }

        @Override
        public void visit(
                ThreadContext context,
                RubyHash other,
                IRubyObject key,
                IRubyObject otherVal,
                int index,
                RubyHash target) {
            IRubyObject currentVal = target.fastARef(key);
            IRubyObject newVal = otherVal;

            // An absent key takes otherVal as is, which is what newVal already holds.
            if (currentVal != null) {
                if (currentVal instanceof RubyHash && otherVal instanceof RubyHash) {
                    // Merge into a copy like ActiveSupport so shared or frozen nested hashes are
                    // never mutated.
                    if (isPlainHash(context, currentVal)) {
                        RubyHash merged = (RubyHash) ((RubyHash) currentVal).dup();
                        ((RubyHash) otherVal).visitAll(context, this, merged);
                        newVal = merged;
                    } else {
                        // ActiveSupport recurses as this_val.deep_merge(other_val), so a nested
                        // subclass gets its own override too.
                        newVal =
                                Helpers.invoke(
                                        context,
                                        currentVal,
                                        "deep_merge",
                                        new IRubyObject[] {otherVal},
                                        block);
                    }
                } else if (block.isGiven()) {
                    newVal = block.call(context, new IRubyObject[] {key, currentVal, otherVal});
                }
            }

            target.op_aset(context, key, newVal);
        }
    }
}
