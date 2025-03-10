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
    public static IRubyObject deepMerge(ThreadContext context, IRubyObject self, IRubyObject other, Block block) {
        RubyHash selfHash = self.convertToHash();
        RubyHash dupedHash = (RubyHash) selfHash.dup();
        RubyHash otherHash = other.convertToHash();
        deepMergeHashes(context, dupedHash, otherHash, block);
        return dupedHash;
    }

    @JRubyMethod(name = "deep_merge!", required = 1)
    public static IRubyObject deepMergeBang(ThreadContext context, IRubyObject self, IRubyObject other, Block block) {
        RubyHash selfHash = self.convertToHash();
        RubyHash otherHash = other.convertToHash();
        deepMergeHashes(context, selfHash, otherHash, block);
        return selfHash;
    }

    private static void deepMergeHashes(ThreadContext context, RubyHash self, RubyHash other, Block block) {
        for (Object k : other.keySet()) {
            IRubyObject key = (IRubyObject) k;
            IRubyObject currentVal = self.op_aref(context, key);
            IRubyObject otherVal = other.op_aref(context, key);

            if (currentVal.isNil()) {
                self.op_aset(context, key, otherVal);
            } else if (currentVal instanceof RubyHash && otherVal instanceof RubyHash) {
                RubyHash currentHash = (RubyHash) currentVal;
                currentHash = (RubyHash) currentHash.dup();
                RubyHash otherHash = (RubyHash) otherVal;
                deepMergeHashes(context, currentHash, otherHash, block);
                self.op_aset(context, key, currentHash);
            } else if (block.isGiven()) {
                IRubyObject result = block.call(context, new IRubyObject[] { key, currentVal, otherVal });
                self.op_aset(context, key, result);
            } else {
                self.op_aset(context, key, otherVal);
            }
        }
    }
}
