#!/usr/bin/python

import sys

hosts = sys.argv[1:]
hostDict = {}

hostDict["172.2.0.121"] = "10.0.0.2"
hostDict["172.2.0.117"] = "10.0.0.3"
hostDict["172.2.0.116"] = "10.0.0.3"
hostDict["172.2.0.122"] = "10.0.0.7"
hostDict["172.2.0.123"] = "10.0.0.3"
hostDict["172.2.0.115"] = "10.0.0.7"
hostDict["172.2.0.114"] = "10.0.0.2"
hostDict["172.2.0.119"] = "10.0.0.2"
hostDict["172.2.0.120"] = "10.0.0.3"
hostDict["172.2.0.118"] = "10.0.0.3"
hostDict["172.2.0.113"] = "10.0.0.7"
hostDict["172.2.0.112"] = "10.0.0.2"
hostDict["172.2.0.111"] = "10.0.0.2"
hostDict["172.2.0.110"] = "10.0.0.7"

for host in hosts:
    print(hostDict.get(host))
