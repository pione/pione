#!/bin/bash

NAME=`pione-val '$*'`
OUT=`pione-val '$O[1]'`
DATA=`pione-val '$I[1]'`

gnuplot <<EOF
set title "scores of $NAME"
set style fill solid border lc rgb "black"
set ylabel "score"
set xrange [-1:16]
set yrange [0:100]

set terminal png
set output "$OUT"

plot "$DATA" using 0:2:xtic(1) with boxes notitle
EOF
