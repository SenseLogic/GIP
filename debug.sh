#!/bin/sh
set -x
dmd -debug -g -gf -gs -m64 gip.d
rm *.o
