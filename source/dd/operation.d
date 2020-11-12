module dd.operation;

import dd.diagrams;

import std.range;
import std.traits;
import std.conv;

/**
 * MDD Operations
 * - References: Decision Diagrams: Constraints and Algorithms, G. Perez
 */
enum MDD_BINOP {
    UNION="||",
    INTERSECTION="&&",
    PLUS="+",
    MINUS="-",
    MULT="*",
    DIV="/",
    MODULO="%",
    EQ="==",
    NE="!=",
    LT="<",
    GT=">",
    LE="<=",
    GE=">="
}

// TODO cache computation results (processed table, unique table)
// currently this algorithm builds a reduced MDD out of the result RES
ROMDD apply(ROMDD X, ROMDD Y, immutable MDD_BINOP op, ref DDContext ctx) @safe
{
    return ROMDD(apply(X.mdd, Y.mdd, op, ctx));
}

MDD apply(MDD X, MDD Y, immutable MDD_BINOP op, ref DDContext ctx) @safe
{
    if(X.isTerminal && Y.isTerminal) return boolApply(X, Y, op);

    // TODO cache
    ulong d = X.bound;
    MDD res = MDD(d, ctx);

    foreach(i; iota(0,d)) {
        debug{ import std.stdio;
            writeln("---");
            writeln(to!string(X.id) ~": "~to!string(X.level));
            writeln(to!string(Y.id) ~": "~to!string(Y.level));
        }
        MDD nX = (X.level < Y.level) ? X : X.getEdge(i);
        MDD nY = (X.level > Y.level) ? Y : Y.getEdge(i);
        res.createEdge(i, apply(nX, nY, op, ctx));
    }

    return res;
}

MDD boolApply(MDD X, MDD Y, immutable MDD_BINOP op) @safe
{
    assert(X.isTerminal() && Y.isTerminal(), "boolApply must be called on two terminal nodes");

    int res = true;
    switch_op: final switch(op) {
        static foreach(_oper; EnumMembers!MDD_BINOP) {
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
                     MDD_BINOP.UNION) == asMDD(TT()));

    assert(boolApply(asMDD(TT()), asMDD(FF()),
                     MDD_BINOP.INTERSECTION) == asMDD(FF()));

    // BDD/MDD apply
    DDContext ctx;
    auto X = MDD(2, ctx); // actually a BDD
    auto t = TT();
    auto f = FF();
    auto n = Node(2, ctx.nextID());
    auto dummy = Node(2, ctx.nextID());

    dummy.createEdge(0, asMDD(t));
    dummy.createEdge(1, asMDD(t));
    n.createEdge(0, asMDD(f));
    n.createEdge(1, asMDD(dummy));
    X.createEdge(0, asMDD(f));
    X.createEdge(1, asMDD(n));

    auto Y = MDD(2, ctx);
    Y.createEdge(0, asMDD(f));
    Y.createEdge(1, asMDD(t));

    import dd.dot;
    auto rX = ROMDD(X);
    auto rY = ROMDD(Y);
    auto res = apply(rX, rY, MDD_BINOP.NE, ctx);

    auto dot = "x.dot";
    writeln("[dot] Saving file: "~dot);
    rX.printDot(dot);

    dot = "y.dot";
    writeln("[dot] Saving file: "~dot);
    rY.printDot(dot);

    dot = "apply_romdd.dot";
    writeln("[dot] Saving file: "~dot);
    res.printDot(dot);
}

