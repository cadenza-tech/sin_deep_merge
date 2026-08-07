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
        RubyHash dupedHash = (RubyHash) self.convertToHash().dup();
        otherHash.visitAll(context, new DeepMergeVisitor(block), dupedHash);
        return dupedHash;
    }

    @JRubyMethod(name = "deep_merge!", required = 1)
    public static IRubyObject deepMergeBang(
            ThreadContext context, IRubyObject self, IRubyObject other, Block block) {
        RubyHash selfHash = self.convertToHash();
        selfHash.modify();
        RubyHash otherHash = other.convertToHash();
        otherHash.visitAll(context, new DeepMergeVisitor(block), selfHash);
        return selfHash;
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
