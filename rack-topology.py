#!/usr/bin/python

import sys
import urllib2
import json
import re
import os
import datetime

DEBUG=1

def createFile(filename, data, append="w"):
    if not os.path.exists(filename):
        open(filename, 'w+').close()
    file = open(filename, append)
    file.write(data)
    file.close()

def readFile(filename):
    file = open(filename, 'r')
    return file

def httpReq(method, url, data=None):
    jsession = login()
    request = urllib2.Request(url, data, headers={"Cookie": jsession})
    request.get_method = lambda: method
    try:
        response = urllib2.urlopen(request)
        return response
    except Exception as e:
        raise e

def login():
    request = urllib2.Request("https://10.0.0.100:8443/serengeti/j_spring_security_check?j_username=administrator@vsphere.local&j_password=Password123!", "")
    response = urllib2.urlopen(request)
    try:
        jsession = re.match(r"(^JSESSIONID.*); Path.*", "".join(response.info().getheader('Set-Cookie')), re.MULTILINE).group(1)
        return jsession
    except Exception as e:
        raise e

def getTopology():
    data = httpReq("GET", "https://10.0.0.100:8443/serengeti/api/cluster/cust3/rack").read()
    createFile("/var/log/hadoop-hdfs/BDE-topology.json", data)

def getRack(host):
    data = readFile("/var/log/hadoop-hdfs/BDE-topology.json").read()
    topology = json.loads(data)
    return re.sub(r"^/", "", topology.get(host))

hosts = sys.argv[1:]

if DEBUG == 1:
    file = createFile("/var/log/hadoop-hdfs/topology-bebug.log", str(datetime.datetime.now()) + " - ran\n", "a")
try:
    getTopology()
except Exception as e:
    file = createFile("/var/log/hadoop-hdfs/topology-error.log", str(datetime.datetime.now()) + " - error: " + e.read() + "\n", "a")
for host in hosts:
    print("/cls1/rack_" + getRack(host))
