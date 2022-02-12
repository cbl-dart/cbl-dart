#! /bin/bash -e
#
# This script has been adopted and modified from the Couchbase Lite C repository.
#
# Generates the CBL Dart exported symbols list for the Apple, Microsoft and GNU linkers.
# The files are written to the 'generated' subdirectory,
# with extensions '.def' (MS), '.exp' (Apple), '.gnu' (GNU).

SCRIPT_DIR=`dirname $0`
cd "$SCRIPT_DIR/generated"

../format_apple.awk   <../CBL_Dart_Exports.txt              >CBL_Dart.exp
../format_linux.awk   <../CBL_Dart_Exports.txt              >CBL_Dart.gnu
../format_windows.awk <../CBL_Dart_Exports.txt              >CBL_Dart.def
