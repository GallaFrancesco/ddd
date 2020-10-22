module dd.dot;

import dd.decision;

import std.stdio;
import std.range;
import std.conv : to;

void printDot(DD)(DD mdd, immutable string outname) @trusted
{
    auto outf = File(outname, "w");
    printDot(mdd, outf);
}

void printDot(DD)(DD mdd, File outf) @trusted
{
    outf.write("digraph G{\n");
    _printDotImpl(mdd, outf);
    outf.write("}\n");
}

void _printDotImpl(DD)(DD mdd, File outf) @trusted
{
    import std.stdio;
    foreach(i; iota(0, mdd.bound)) {
        auto child = mdd.getEdge(i);
        if(!child.isFF()) {
            string cid = (child.isTT()) ? "T" : to!string(child.id);
            outf.write(
                       to!string(mdd.id)
                       ~ " -> "
                       ~ cid
                       ~ " [label = "
                       ~ to!string(i)
                       ~ " ]\n");
            _printDotImpl(child, outf);
        }
    }
}

unittest
{
    // initialize a MDD with bound 2 (a BDD) and two terminal nodes
    DDContext ctx;
    auto bdd = MDD(2,ctx);
    auto t = TT();
    auto f = FF();
    auto n = Node(2, ctx.nextID());

    // add two edges with terminal nodes as target
    n.createEdge(0, MDD(DDNode(f)));
    n.createEdge(1, MDD(DDNode(t)));
    bdd.createEdge(0, MDD(DDNode(t)));
    bdd.createEdge(1, MDD(DDNode(n)));

    string dot = "bdd.dot";
    writeln("[dot] Saving file: "~dot);
    bdd.printDot(dot);

    auto robdd = ROMDD(bdd);
    dot = "robdd.dot";
    writeln("[dot] Saving file: "~dot);
    robdd.printDot(dot);
}
