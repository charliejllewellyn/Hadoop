#!/usr/bin/python

import subprocess
import re

data = subprocess.Popen(["hdfs", "fsck", "/user/serengeti/", "-files", "-blocks", "-racks"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
out, err = data.communicate()

def getBlockLocation():
    blocks = list()
    for line in out.split('\n'):
        filename = re.match(r"(^\/user.*)\S.*byte.*", line)
        if filename:
            filename1 = filename.group(1)
        if re.match(r"^0. BP.*", line):
            racks = sorted(re.match(r"0. BP.*\[.*(172\.2\.0\....):50010.*,.*(172\.2\.0\....):50010.*,.*(172\.2\.0\....):50010.*", line).group(1,2,3))
            block = racks[0] + racks[1] + racks[2]
            #Cluster cust3 - Rack 10.0.0.2
            if block == "172.2.0.112172.2.0.119172.2.0.121":
                print("FAILED: " + filename1 + block)
            #Cluster cust3 - Rack 10.0.0.3
            if block == "172.2.0.118172.2.0.120172.2.0.123":
                print("FAILED: " + filename1 + block)
            #Cluster cust3 - Rack 10.0.0.7
            if block == "172.2.0.113172.2.0.115172.2.0.122":
                print("FAILED: " + filename1 + block)

getBlockLocation()
