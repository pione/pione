#!/usr/bin/env gnuplot

set title "scores of " . name
set style fill solid border lc rgb "black"
set ylabel "score"
set xrange [-1:16]
set yrange [0:100]

set terminal png
set output out

plot data using 0:2:xtic(1) with boxes notitle
