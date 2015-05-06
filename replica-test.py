#!/usr/bin/python

import subprocess
import re

data = subprocess.Popen(["hdfs", "fsck", "/tmp/", "-files", "-blocks", "-racks"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
out, err = data.communicate()

def getBlockLocation():
    blocks = list()
    for line in out.split('\n'):
        filename = re.match(r"(^\/user.*)\S.*byte.*", line)
        if filename:
            filename1 = filename.group(1)
        if re.match(r"^0. BP.*", line):
            #racks = sorted(re.match(r"0. BP.*\[.*(192\.168\.0\..*):50010.*,.*(192\.168\.0\..*):50010.*,.*(192\.168\.0\..*):50010.*", line).group(1,2,3))
            racks = sorted(re.match(r"0. BP.*\[.*/hadoop01/(.*)\/.*:50010.*,.*/hadoop01/(.*)\/.*:50010.*,.*/hadoop01/(.*)\/.*:50010.*", line).group(1,2,3))
            block = racks[0] + racks[1] + racks[2]
            if racks[0] == racks[1]:
                print line
            if racks[0] == racks[2]:
                print line
            if racks[1] == racks[2]:
                print line

getBlockLocation()
