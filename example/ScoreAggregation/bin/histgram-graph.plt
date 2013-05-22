#!/usr/bin/env gnuplot

set title "Histgram of member's mean score"

set style fill solid border lc rgb "black"
set xrange [0:10]
set yrange [0:20]

set terminal png
set output out

plot data using 0:2:xtic(1) with boxes notitle
