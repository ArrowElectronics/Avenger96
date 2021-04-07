#!/usr/bin/python3

import os
import sys

LINE_LENGTH = 80
NUM_TOKEN = 8
ARRAY_INIT = "static const u8 ap1302_fw_bootdata%i[ ] = {"
array_cnt = 1
out_array = []

def parse_header( tokens ):
    global pll_init_size, checksum

    for token in tokens:
        if token.startswith("pll_init_size="):
            pll_init_size=int(token[15:-1])
        if token.startswith("checksum="):
            checksum=int(token[10:-1],16)
    return


def parse_token( token ):
    if len(token) == 2:
        bytes = [int(token[0:2],16)]
    elif len(token) == 4:
        bytes = [int(token[0:2],16), int(token[2:4],16)]
    elif len(token) == 8:
        bytes = [int(token[0:2],16), int(token[2:4],16), int(token[4:6],16), int(token[6:8],16)]
    return bytes


def num_to_bytes( num, array, start ):
    array[start] = num & 0xff
    array[start+1] = (num >> 8) & 0xff
    array[start+2] = (num >> 16) & 0xff
    array[start+3] = (num >> 24) & 0xff
    return

if len(sys.argv) < 2 :
    print( "Usage: parse_xml.py <xml_file>" )
    sys.exit(1)

with open(sys.argv[1]) as f:
    content = f.readlines()

pll_init_size = 0
checksum = 0
dump_start = 0
addr = 0
full_array = [0, 1, 2, 3, 0, 1, 2, 3, 0, 1, 2, 3, 0, 0, 0, 0]
chunk_num = 1
line_num = 0

for line in content:
    line_num = line_num + 1
    dump_start = dump_start + 1
    tokens = line.split()
    if len( tokens ) > 0 and tokens[0] == "<dump" :
        parse_header( tokens )
        if pll_init_size > 0:
            break

num_to_bytes(checksum, full_array, 0)
num_to_bytes(pll_init_size, full_array, 4)
        
for line in content[dump_start:]:
    line_num = line_num + 1
    dump_start = dump_start + 1
    if "/dump" in line:
        break
    tokens = line.split()
    for token in tokens:
        if len(token) > 0:
            full_array = full_array + parse_token( token )

num_to_bytes(len(full_array) - 16, full_array, 8)

sys.stdout.buffer.write(bytearray(full_array))
