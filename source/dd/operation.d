module dd.operation;

import dd.decision;

import std.range;

/**
 * MDD Operations
 */
enum MDD_OP { OP1, OP2 }

MDD apply(MDD X, MDD Y, immutable MDD_OP op, ref DDContext ctx) @safe
{
    assert(X.bound == Y.bound, "MDDs must have the same variable bound for apply");

    if(X.isTerminal && Y.isTerminal) return boolApply(X, Y, op);

    // TODO cache
    ulong d = X.bound;
    MDD res = MDD(d, ctx);

    foreach(i; iota(0,d)) {
        // TODO wrapper around sumtype
        res.createEdge(i, apply(X.getEdge(i), Y.getEdge(i), op, ctx));
    }

    return res;
}

MDD boolApply(MDD X, MDD Y, immutable MDD_OP op) @safe
{
    // TODO complete
    TT t;
    return MDD(DDNode(t));
}

