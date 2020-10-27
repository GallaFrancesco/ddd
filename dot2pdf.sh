#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "Usage: ./dot2pdf [filename]"
    exit
fi

out=${1%.*}
dot -Tpdf $1 -o $out.pdf
echo "Generated $out.pdf"
