module dd.decision;

import sumtype;

import std.range;
import std.conv;

/**
 * Wrapper around the root nodes of MDDs
 */
struct MDD
{
private:
    ulong current_id = 0;
public:
    _DDNode root;
    ulong bound;
    alias root this;

    this(ulong b) @safe
    {
        root = Node(b, current_id++);
        bound = b;
    }

    this(_DDNode node) @safe
    {
        node.match!(
                    (TT n)   { root = asNode(n); bound = 1; },
                    (FF n)   { root = asNode(n); bound = 1; },
                    (Node n) { root = asNode(n); bound = n.size; current_id = n.id+1; }
                    );

    }

    void createEdge(immutable ulong label, MDD mdd) @safe
    {
        root.tryMatch!((Node n) => n.createEdge(label, mdd.root));
    }

    MDD getEdge(immutable ulong label) @safe
    {
        return root.tryMatch!((Node n) => MDD(n.getEdge(label)));
    }

    ulong size() @safe
    {
        return root.tryMatch!((Node n) => n.size);
    }
        
    ulong id() @safe
    {
        return root.tryMatch!((Node n) => n.id);
    }

    bool isTerminal() @safe
    {
        return root.match!(
                           (Node n) => false,
                           (FF f) => true,
                           (TT t) => true
                           );
    }
}

alias _DDNode = SumType!(Node, TT, FF);
alias asNode = _DDNode;

struct TT { bool val = true; } // terminal TRUE
struct FF { bool val = false; } // terminal FALSE

struct Node
{
private:
    _DDNode[] children;
public:
    immutable ulong id;          // TODO enforce unique
    immutable ulong size;

    this(immutable ulong sz, immutable ulong ident) @safe
    {
        size = sz;
        id = ident;
        foreach(ref c; iota(0,sz)) {
            children ~= _DDNode(FF());
        }
    }

    // set the target node of an edge
    void createEdge(immutable ulong label, _DDNode node) @safe
    {
        assert(label < size, "Invalid label for createEdge");
        children[label] = node;
    }

    // get the node for edge label
    _DDNode getEdge(immutable ulong label) @safe
    {
        assert(label < size, "Invalid label for getEdge");
        return children[label];
    }
}

/**
 * Operations
 */
enum MDD_OP { OP1, OP2 }

MDD apply(MDD X, MDD Y, immutable MDD_OP op) @safe
{
    assert(X.bound == Y.bound, "MDDs must have the same variable bound for apply");

    if(X.isTerminal && Y.isTerminal) return boolApply(X, Y, op);

    // TODO cache
    ulong d = X.bound;
    MDD res = MDD(d);

    foreach(i; iota(0,d)) {
        // TODO wrapper around sumtype
        res.createEdge(i, apply(X.getEdge(i), Y.getEdge(i), op));
    }

    return res;
}

MDD boolApply(MDD X, MDD Y, immutable MDD_OP op) @safe
{
    // static assert((is(X == TT) || is(X == FF)) &&
    //           (is(Y == TT) || is(Y == FF)));
    TT t;
    return MDD(asNode(t));
}
