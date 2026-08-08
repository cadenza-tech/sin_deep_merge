package sin_deep_merge;

import org.jruby.Ruby;
import org.jruby.RubyHash;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
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
        RubyHash otherHash = other.convertToHash();
        RubyHash dupedHash = (RubyHash) ((RubyHash) self).dup();
        deepMergeInto(context, otherHash, dupedHash, block);
        return dupedHash;
    }

    @JRubyMethod(name = "deep_merge!", required = 1)
    public static IRubyObject deepMergeBang(
            ThreadContext context, IRubyObject self, IRubyObject other, Block block) {
        RubyHash selfHash = (RubyHash) self;
        selfHash.modify();
        RubyHash otherHash = other.convertToHash();
        deepMergeInto(context, otherHash, selfHash, block);
        return selfHash;
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
            if (currentVal == null) {
                target.op_aset(context, key, otherVal);
            } else if (currentVal instanceof RubyHash && otherVal instanceof RubyHash) {
                // Merge into a copy like ActiveSupport so shared or frozen nested hashes are
                // never mutated.
                RubyHash merged = (RubyHash) ((RubyHash) currentVal).dup();
                ((RubyHash) otherVal).visitAll(context, this, merged);
                target.op_aset(context, key, merged);
            } else if (block.isGiven()) {
                IRubyObject result =
                        block.call(context, new IRubyObject[] {key, currentVal, otherVal});
                target.op_aset(context, key, result);
            } else {
                target.op_aset(context, key, otherVal);
            }
        }
    }
}
