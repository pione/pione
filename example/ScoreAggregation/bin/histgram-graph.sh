#!/bin/bash

DATA=`pione-val '$I[1]'`
OUT=`pione-val '$O[1]'`

gnuplot <<EOF
set title "Histgram of member's mean score"

set style fill solid border lc rgb "black"
set xrange [0:10]
set yrange [0:20]

set terminal png
set output "$OUT"

plot "$DATA" using 0:2:xtic(1) with boxes notitle
EOF

