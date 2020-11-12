#!/bin/bash

DIR=plots
mkdir -p $DIR

if [[ $# -ne 1 ]]; then
    echo "Usage: ./dot2pdf [filename]"
    exit
fi

dot=$(basename $1)
out=$DIR/${dot%.*}.pdf
dot -Tpdf $1 -o $out
echo "Generated $out"
