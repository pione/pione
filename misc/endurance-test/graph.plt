#!/usr/bin/env gnuplot

set datafile separator ","
set key box

set terminal png
set output "endurance-test-time.png"

plot 'endurance-test-time.txt' using 1:2 with points title "real", \
     'endurance-test-time.txt' using 1:3 with points title "user", \
     'endurance-test-time.txt' using 1:4 with points title "sys"

