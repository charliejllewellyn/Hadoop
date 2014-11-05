#!/usr/bin/python

import subprocess
import re

data = subprocess.Popen(["hdfs", "fsck", "/user/serengeti/", "-files", "-blocks", "-racks"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
out, err = data.communicate()
#print(out)
for line in out.split('\n'):
    if re.match(r"^0. BP.*", line):
        racks = re.match(r"0. BP.*\[.*(172\.2\.0\....):50010.*,.*(172\.2\.0\....):50010.*,.*(172\.2\.0\....):50010.*", line)
        print(racks.group(1,2,3).sort())
