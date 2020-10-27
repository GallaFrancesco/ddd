module dd.operation;

import dd.diagrams;

import std.range;
import std.traits;
import std.conv;

/**
 * MDD Operations
 */
enum MDD_OP {
    UNION="||",
    INTERSECTION="&&"
}

MDD apply(MDD X, MDD Y, immutable MDD_OP op, ref DDContext ctx) @safe
{
    assert(X.bound == Y.bound, "MDDs must have the same variable bound for apply");

    if(X.isTerminal && Y.isTerminal) return boolApply(X, Y, op);

    // TODO cache
    ulong d = X.bound;
    MDD res = MDD(d, ctx);

    foreach(i; iota(0,d)) {
        res.createEdge(i, apply(X.getEdge(i), Y.getEdge(i), op, ctx));
    }

    return res;
}

MDD boolApply(MDD X, MDD Y, immutable MDD_OP op) @safe
{
    assert(X.isTerminal() && Y.isTerminal(), "boolApply must be called on two terminal nodes");

    bool res = true;
    switch_op: final switch(op) {
        static foreach(_oper; EnumMembers!MDD_OP) {
        case _oper:
            import std.stdio;
            mixin("res = X.value "~cast(string)_oper~" Y.value;");
            break switch_op;
        }
    }
    return (res) ? asMDD(TT()) : asMDD(FF());
}

unittest {
    assert(boolApply(asMDD(TT()), asMDD(FF()),
                     MDD_OP.UNION) == asMDD(TT()));

    assert(boolApply(asMDD(TT()), asMDD(FF()),
                     MDD_OP.INTERSECTION) == asMDD(FF()));
}

