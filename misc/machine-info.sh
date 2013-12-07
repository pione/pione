#!/bin/sh

cat <<EOF

Test Matchine Information
=========================

EOF

# kernel
uname -a

# distribution name
head -n1 /etc/issue

# memory size
grep MemTotal /proc/meminfo

# cpus
grep -E "processor|model name|cpu MHz|cache size" /proc/cpuinfo
echo
