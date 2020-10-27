module dd.dot;

import dd.decision;

import std.stdio;
import std.range;
import std.conv : to;
debug {
    import std.stdio;
}

void printDot(DD)(ref DD mdd, immutable string outname) @trusted
{
    auto outf = File(outname, "w");
    printDot(mdd, outf);
}

void printDot(DD)(ref DD mdd, File outf) @trusted
{
    outf.write("digraph G{\n");
    _printDotImpl(mdd, outf);
    outf.write("}\n");
}

void _printDotImpl(DD)(ref DD mdd, File outf) @trusted
{
    foreach(i; iota(0, mdd.bound)) {
        // debug { writeln("[_printDotImpl] MDD bound: "~to!string(mdd.bound)~", label: "~to!string(i)); }
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
