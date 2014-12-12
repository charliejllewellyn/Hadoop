#!/usr/bin/python

import psycopg2
import re
import subprocess
import sys

cluster = ""

def checkArgs():
        if( len(sys.argv) ) < 2:
                print("please provide a cluster name, e.g. " + sys.argv[0] + " cluster1")
                sys.exit()
        else:
                global cluster
                cluster = sys.argv[1]

def sshCmd( host, command ):
        ssh = subprocess.Popen(["ssh", "%s" % host, command],
                shell=False,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE)
        result = ssh.stdout.readlines()
        if result == []:
                error = ssh.stderr.readlines()
                print >>sys.stderr, "ERROR: %s" % error
        else:
                return result

def queryPsql ( query ):
    try:
        conn = psycopg2.connect("dbname='serengeti' user='serengeti' host='localhost'")
        cur = conn.cursor()
        cur.execute(query)
        rows = cur.fetchall()
        return rows
    except:
        print( "Unable to connect to the database" )

def writeTopology():
        vmToHost = queryPsql( "select nic.ipv4_address, host_name from node, nic where node.id = nic.node_id and vm_name like '" + cluster + "-%'")
        data = ""
        for line in vmToHost:
                data = str(data) + "\n" + line[1] + " " + line[0]
        for vm in vmToHost:
                is_valid = re.match("^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$", vm[0])
                if is_valid:
                        sshCmd(vm[0], "echo '" + str(data) + "' > /tmp/test")

checkArgs()
writeTopology()
