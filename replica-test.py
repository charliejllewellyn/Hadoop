#!/usr/bin/python

import subprocess
import re

data = subprocess.Popen(["hdfs", "fsck", "/user/serengeti/", "-files", "-blocks", "-racks"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
out, err = data.communicate()
for line in out.split('/default-rack/'):
    print(line)
