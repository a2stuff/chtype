#!/bin/bash

# Use Cadius to create a disk image for distribution
# https://github.com/mach-kernel/cadius

set -e

PACKDIR=$(mktemp -d)
IMGFILE="out/chtype.po"
VOLNAME="chtype"

rm -f "$IMGFILE"
cadius CREATEVOLUME "$IMGFILE" "$VOLNAME" 140KB --no-case-bits --quiet

add_file () {
    cp "$1" "$PACKDIR/$2"
    cadius ADDFILE "$IMGFILE" "/$VOLNAME" "$PACKDIR/$2" --no-case-bits --quiet
}

add_file "out/chtype.BIN" "chtype#062000"
add_file "out/chtime.BIN" "chtime#062000"

rm -r "$PACKDIR"

cadius CATALOG "$IMGFILE"
