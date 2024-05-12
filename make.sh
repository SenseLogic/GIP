#!/bin/sh
set -x
dmd -m64 gip.d
rm *.o
