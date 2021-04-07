#!/usr/bin/python

import os
import sys

LINE_LENGTH = 80
NUM_TOKEN = 8
ARRAY_INIT = "static const u8 ap1302_fw_bootdata%i[ ] = {"
array_cnt = 1


def le2be16( word ):
    num=int(word.split(",")[0],16)
    ret = " 0x%02X," % (num / 256)
    return ret + " 0x%02X," % (num % 256)


def le2be32( num ):
    bytes=[0,1,2,3]
    for cnt in range(0,4):
        bytes[3 - cnt] = num & 0xff
        num = num >> 8
    ret = " 0x%02X, 0x%02X, 0x%02X, 0x%02X," % tuple([b for b in bytes])
    return ret


def split_burst( words ):
    global array_cnt
    print(ARRAY_INIT % array_cnt)
    array_cnt = array_cnt + 1
    print( "   " + le2be16(words[1]) )
    start = 2
    while start < len(words):
        line = "   "
        l = len(words) - start
        if l > NUM_TOKEN:
            l = NUM_TOKEN
        for w in words[start:start+l]:
            line = line + le2be16(w)
        print line
        start = start + l
    print( "};\n" )


def split_reg( words ):
    global array_cnt
    print(ARRAY_INIT % array_cnt)
    array_cnt = array_cnt + 1
    if len(words[2]) > 7 :
        print( "    %s %s\n};\n" % ( le2be16(words[1]), le2be32(int(words[2],16)) ) )
    else:
        print( "    %s %s\n};\n" % ( le2be16(words[1]), le2be16(words[2]) ) )


def split_line( line ):
    words = line.split()
    if len(words) < 1 :
        return
    if words[0] == "REG_BURST=":
        split_burst( words )
    elif words[0] == "REG=":
        split_reg( words )


if len(sys.argv) < 2 :
    print "Usage: parse_register_ini.py <ini_file>"
    sys.exit(1)

with open(sys.argv[1]) as f:
    content = f.readlines()

for line in content:
    split_line( line )
