#!/usr/bin/python

import os
import sys

LINE_LENGTH = 80
NUM_TOKEN = 8
ARRAY_INIT = "static const u8 ap1302_fw_bootdata%i[ ] = {"
array_cnt = 1


def parse_header( tokens ):
    global pll_init_size, checksum

    for token in tokens:
        if token.startswith("pll_init_size="):
            pll_init_size=int(token[15:-1])
        if token.startswith("checksum="):
            checksum=int(token[10:-1],16)
    if pll_init_size > 0:
        print "#define AP1302_FW_CHECKSUM  0x%04x" % checksum
        print
    return


def parse_token( token ):
    if len(token) == 2:
        bytes = [int(token[0:2],16)]
    elif len(token) == 4:
        bytes = [int(token[0:2],16), int(token[2:4],16)]
    elif len(token) == 8:
        bytes = [int(token[0:2],16), int(token[2:4],16), int(token[4:6],16), int(token[6:8],16)]
    return bytes


def hex_dump( bytes ):
    tot_len = len(bytes)
    addr=0
    while tot_len > 0:
        l = 16
        if l > tot_len:
            l = tot_len
        print "   ",
        for i in range(0,l):
            print ("0x%02X," % bytes[addr + i]),
        print
        addr = addr + l
        tot_len = tot_len - l
    return


def print_burst( bytes ):
    global chunk_num

    print ARRAY_INIT % chunk_num
    chunk_num = chunk_num + 1
    if len(bytes) <= 6:
        hex_dump( bytes )
    else:
        hex_dump( bytes[0:2] )
        hex_dump( bytes[2:] )
    print "};\n"
    return


if len(sys.argv) < 2 :
    print "Usage: parse_xml.py <xml_file>"
    sys.exit(1)

with open(sys.argv[1]) as f:
    content = f.readlines()

pll_init_size = 0
checksum = 0
dump_start = 0
addr = 0
full_array = []
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

for line in content[dump_start:]:
    line_num = line_num + 1
    dump_start = dump_start + 1
    if "/dump" in line:
        break
    tokens = line.split()
    for token in tokens:
        if len(token) > 0:
            full_array = full_array + parse_token( token )

tot_len = len(full_array)
while tot_len > 0:
    if addr < pll_init_size:
        ln = pll_init_size
    else:
        ln = 8192

    max = 8192 - addr % 8192
    if ln > max:
        ln = max

    if ln > tot_len:
        ln = tot_len

    if addr == pll_init_size:
        print_burst([0x60, 0x02, 0x00, 0x02])

    bytes = [(addr & 0x1fff)>>8 | 0x80, addr&0xff] + full_array[addr:addr+ln]
    print_burst( bytes )
    addr = addr + ln
    tot_len = tot_len - ln

print_burst([0x60, 0x02, 0xff, 0xff])
