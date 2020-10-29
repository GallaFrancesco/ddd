module dd.operation;

import dd.diagrams;

import std.range;
import std.traits;
import std.conv;


/**
 * MDD Operations
 * - References: miner notes, thesis 
 */
enum MDD_OP {
    UNION="||",
    INTERSECTION="&&"
}

// TODO cache computation results (processed table, unique table)
// currently this algorithm builds a reduced MDD out of the result RES
ROMDD apply(ROMDD X, ROMDD Y, immutable MDD_OP op, ref DDContext ctx) @safe
{
    return ROMDD(apply(X.mdd, Y.mdd, op, ctx));
}

MDD apply(MDD X, MDD Y, immutable MDD_OP op, ref DDContext ctx) @safe
{
    // assert(X.bound == Y.bound,
    //        "MDDs must have the same bound for apply: "
    //        ~ to!string(X.bound)
    //        ~ " != "
    //        ~ to!string(Y.bound)
    //        );

    if(X.isTerminal && Y.isTerminal) return boolApply(X, Y, op);

    // TODO cache
    ulong d = X.bound;
    MDD res = MDD(d, ctx);

    foreach(i; iota(0,d)) {
        MDD nX = X.isTerminal() ? X : X.getEdge(i);
        MDD nY = Y.isTerminal() ? Y : Y.getEdge(i);
        res.createEdge(i, apply(nX, nY, op, ctx));
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
    import std.stdio;

    // boolean apply
    assert(boolApply(asMDD(TT()), asMDD(FF()),
                     MDD_OP.UNION) == asMDD(TT()));

    assert(boolApply(asMDD(TT()), asMDD(FF()),
                     MDD_OP.INTERSECTION) == asMDD(FF()));

    // BDD/MDD apply
    DDContext ctx;
    auto X = MDD(2, ctx); // actually a BDD
    auto t = TT();
    auto f = FF();
    auto n = Node(2, ctx.nextID());

    n.createEdge(0, asMDD(f));
    n.createEdge(1, asMDD(t));
    X.createEdge(0, asMDD(f));
    X.createEdge(1, asMDD(n));

    auto Y = MDD(2, ctx);
    Y.createEdge(0, asMDD(f));
    Y.createEdge(1, asMDD(t));


    import dd.dot;
    auto rX = ROMDD(X);
    auto rY = ROMDD(Y);
    auto res = apply(rX, rY, MDD_OP.UNION, ctx);

    auto dot = "x.dot";
    writeln("[dot] Saving file: "~dot);
    rX.printDot(dot);

    dot = "y.dot";
    writeln("[dot] Saving file: "~dot);
    rY.printDot(dot);

    dot = "apply_union_robdd.dot";
    writeln("[dot] Saving file: "~dot);
    res.printDot(dot);
}

