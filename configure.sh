#!/bin/bash

script=$0
hadoopClientNet=$1
hadoopDataNet=$2
ownIp=`ifconfig | grep eth -A1 | tail -1 | awk '{print $2}' | awk -F: '{print $NF}'`
date=`date +'%Y%m%dT%H:%M:%S'`
logFile=/usr/local/bin/configure.log
templateZoneFile=/usr/local/bin/zonefile.template

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
        sed -i 's=allow-query     { localhost; };=allow-query     { localhost; '$hadoopClientNet'; '$hadoopDataNet'; };=g' /etc/named.conf
        grep '/etc/named/hadoop.zones' /etc/named.conf &>/dev/null
        if [ $? != 0 ]; then
                echo 'include "/etc/named/hadoop.zones";' >> /etc/named.conf
        fi
        # Return first three octets of Hadoop address space so we can write out our addresses
        shortHadoopClientNet=`echo $hadoopClientNet | awk -F. '{print $1"."$2"."$3}'`
        shortHadoopDataNet1=`echo $hadoopDataNet | awk -F. '{print $1"."$2}'`
        shortHadoopDataNet2=`echo $hadoopDataNet | awk -F. '{print $3}'`
        count=1
        # Create named zonefiles and configure named to read them
        echo -e "zone \"client.hadoop.local\" IN {\n\ttype master;\n\tfile \"client.hadoop.local\";\n\tallow-update { none; };\n};" > /etc/named/hadoop.zones
        echo -e "zone \"data.hadoop.local\" IN {\n\ttype master;\n\tfile \"data.hadoop.local\";\n\tallow-update { none; };\n};" >> /etc/named/hadoop.zones
        revZone=`echo $hadoopClientNet | awk -F. '{print $3"."$2"."$1}'`
        echo -e "zone \"$revZone.in-addr.arpa\" IN {\n\ttype master;\n\tfile \"$revZone\";\n\tallow-update { none; };\n};" >> /etc/named/hadoop.zones
        cat $templateZoneFile > /var/named/client.hadoop.local
        sed -i "s=TTL 3H=TTL 86400\n\$ORIGIN client.hadoop.local.=g" /var/named/client.hadoop.local
        cat $templateZoneFile > /var/named/data.hadoop.local
        sed -i "s=TTL 3H=TTL 86400\n\$ORIGIN data.hadoop.local.=g" /var/named/data.hadoop.local
        cat $templateZoneFile > /var/named/$revZone
        sed -i "s=TTL 3H=TTL 86400\n\$ORIGIN $revZone.IN-ADDR.ARPA.=g" /var/named/$revZone
        for num in {0..4}; do
                zone=`echo $hadoopDataNet | awk -F. '{print $3+'$num'"."$2"."$1}'`
                echo -e "zone \"$zone.in-addr.arpa\" IN {\n\ttype master;\n\tfile \"$zone\";\n\tallow-update { none; };\n};" >> /etc/named/hadoop.zones
                cat $templateZoneFile > /var/named/$zone
                sed -i "s=TTL 3H=TTL 86400\n\$ORIGIN $zone.IN-ADDR.ARPA.=g" /var/named/$zone
        done
        # Populate named zone files
        echo gateway    IN      A       $shortHadoopClientNet.254 >> /var/named/client.hadoop.local
        echo 254        IN      PTR     gateway.client.hadoop.local. >> /var/named/`echo $hadoopClientNet | awk -F. '{print $3"."$2"."$1}'`
        echo ambari     IN      A       $shortHadoopClientNet.253 >> /var/named/client.hadoop.local
        echo 253        IN      PTR     ambari.client.hadoop.local. >> /var/named/`echo $hadoopClientNet | awk -F. '{print $3"."$2"."$1}'`
        for ip in {1..254}; do
                echo client$count    IN      A       $shortHadoopClientNet.$ip >> /var/named/client.hadoop.local
                echo $ip       IN      PTR     client$count.client.hadoop.local. >> /var/named/`echo $hadoopClientNet | awk -F. '{print $3"."$2"."$1}'`
                count=`echo $count+1 | bc`
        done
        for num in {0..4}; do
                for ip in {2..254}; do
                        echo datanode$count    IN      A       $shortHadoopDataNet1.`echo $shortHadoopDataNet2+$num | bc`.$ip >> /var/named/data.hadoop.local
                        echo $ip        IN      PTR     client$count.data.hadoop.local. >> /var/named/`echo $hadoopDataNet | awk -F. '{print $3+'$num'"."$2"."$1}'`
                        count=`echo $count+1 | bc`
                done
        done
        chkconfig named on
        service named restart
}

# Log initalisation
echo -e "######################### $date ####################################\nConfigure script was run with the following parameters:\n$date: $script $hadoopClientNet $hadoopDataNet" >> $logFile

# Check that correct arguments are passed
if [[ ! $hadoopClientNet  =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]] || [[ ! $hadoopDataNet =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        echo -e "$date | FAIL (1): Incorrect arguments passed to the script" >> $logFile
        exit 1
fi

# Run the functions above to configure the server
configureFirewall
configureNamed
