module dd.dot;

import dd.diagrams;

import std.stdio;
import std.range;
import std.conv : to;
debug {
    import std.stdio;
}

void printDot(DD)(DD mdd, immutable string outname) @trusted
{
    auto outf = File(outname, "w");
    printDot(mdd, outf);
}

void printDot(DD)(DD mdd, File outf) @trusted
{
    outf.write("digraph G{\n");
    MDD[ulong] visited;
    _printDotImpl(mdd, outf, visited);
    outf.write("}\n");
}

void _printDotImpl(DD)(DD mdd, File outf, DD[ulong] visited) @trusted
{
    if(mdd.id in visited) return;

    visited[mdd.id] = mdd;

    foreach(i; iota(0, mdd.bound)) {
        auto child = mdd.getEdge(i);
        // debug { writeln("[_printDotImpl] MDD id: "~to!string(mdd.id)~", --("~to!string(i)~")--> "~to!string(child.id)); }
        if(!(child.isTerminal() && child.value == 0)) {
            string cid = (child.isTerminal()) ? "T" : to!string(child.id);
            outf.write(
                       to!string(mdd.id)
                       ~ " -> "
                       ~ cid
                       ~ " [label = "
                       ~ to!string(i)
                       ~ " ]\n");
            _printDotImpl(child, outf, visited);
        }
    }
}
