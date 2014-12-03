#!/bin/bash

script=$0
hadoopClientNet=$1
hadoopDataNet=$2
ownIp=`ifconfig | grep eth -A1 | tail -1 | awk '{print $2}' | awk -F: '{print $NF}'`
date=`date +'%Y%m%dT%H:%M:%S'`
logFile=/usr/local/bin/configure.log

# Function to run commands, check output and log
function runCmdLog {
        $@ #&>/dev/null
        if [ $? == 0 ]; then
                echo -e "$date | SUCCESS ($?): $1" >> $logFile
        else
                echo -e "$date | FAIL ($?): $1" >> $logFile
        fi
}

# Function to add local firewall rules
function configureFirewall {
        runCmdLog "iptables -I INPUT --src $hadoopClientNet -j ACCEPT"
        runCmdLog "iptables -I INPUT --src $hadoopDataNet -j ACCEPT"
        runCmdLog "service iptables save"
}

# Function to create named config files to provide DNS servivces for Hadoop
function configureNamed {
        # Update named.conf to allow queries from hadoop subnets
        ##sed -i "s=allow-query     { localhost; };=allow-query     { localhost; '$hadoopClientNet'; '$hadoopDataNet'; };=g" /etc/named.conf
        # Return first three octets of Hadoop address space so we can write out our addresses
        shortHadoopClientNet=`echo $hadoopClientNet | awk -F. '{print $1"."$2"."$3}'`
        shortHadoopDataNet1=`echo $hadoopDataNet | awk -F. '{print $1"."$2}'`
        shortHadoopDataNet2=`echo $hadoopDataNet | awk -F. '{print $3}'`
        count=1
        echo gateway    IN      A       $hadoopClientNet.254
        echo 254        IN      PTR     gateway.client.hadoop.local.
        echo ambari     IN      A       $hadoopClientNet.253
        echo 253        IN      PTR     ambari.client.hadoop.local.
        for ip in {1..254}; do
                echo client$count    IN      A       $shortHadoopClientNet1.
                echo $ip       IN      PTR     client$count.client.hadoop.local.
                count=`echo $count+1 | bc`
        done
        for num in {0..4}; do
                for ip in {2..254}; do
                        echo datanode$count    IN      A       $shortHadoopDataNet1.`echo $shortHadoopDataNet2+$num | bc`.$ip
                        echo $ip        IN      PTR     client$count.data.hadoop.local.
                        count=`echo $count+1 | bc`
                done
        done
}

# Log initalisation
echo -e "######################### $date ####################################\nConfigure script was run with the following parameters:\n$date: $script $hadoopClientNet $hadoopDataNet" >> $logFile

# Check that correct arguments are passed
if [[ ! $hadoopClientNet  =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]] || [[ ! $hadoopDataNet =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        echo -e "$date | FAIL (1): Incorrect arguments passed to the script" >> $logFile
        exit 1
fi

# Run the functions above to configure the server
##configureFirewall
configureNamed
