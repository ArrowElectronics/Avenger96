#### xml2bin
xml2bin.py creates binary firmware files for the AP1302 ISP and ap1302.ko Linux driver. It converts OnSemi's  .XML format initialization files to binary files. The binary output will start with a 16-byte header followed by the "bootdata" section from the .XML input file. The binary output can be downloaded by ap1302.ko into the AP1302 ISP.
Usage:
```
./xml2bin.py [.XML input] > [binary output file]
```
<br/>

For the AR0430 image sensor this translates to:
```
./xml2bin.py AR0430_Headboard.xml > on_ar0430_headboard.bin
```
For the AR1337 image sensor:
```
./xml2bin.py guido_patch_290520_01.xml > on_ar1337_cdaf_dw9718.290520_01.bin
```