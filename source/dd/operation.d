module dd.operation;

import dd.diagrams;

import std.range;
import std.conv;

/**
 * MDD Operations
 */
enum MDD_OP { UNION, INTERSECTION }

string[MDD_OP] BOOLEAN_OPS;
static this() {
    BOOLEAN_OPS[MDD_OP.UNION] = "||";
    BOOLEAN_OPS[MDD_OP.INTERSECTION] = "&&";
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
    assert(op in BOOLEAN_OPS, "boolApply must be called on a boolean operation, invalid op: "~to!string(op));

    string bop = BOOLEAN_OPS[op];

    // static foreach(
}

unittest {

}

