#!/bin/sh
#

community=$1
host=$2
domainsuffix=net.intern.hoglandet.se

if [[ $4 -lt '1' ]] ; then
  count='1'
else
  count=$4
fi

if [[ $# -lt '2' ]] ; then
  echo "Usage:"
  echo "$0 [snmp community] [device hostname/IP] [neighbor name or 'list'] (count)"
  echo ""
  echo "The list argument is used list all cdp neighbors. The optional count"
  echo "parameters specifies how many physical links should exist between"
  echo "the host and the neighbor."
  exit 3
fi


sysName=( $(snmpbulkwalk -t 1 -r 0 -v2c -c $community $host SNMPv2-MIB::sysName.0 | awk '{print toupper($0)}' | awk -F ": " '{print $2}' | sed "s/'/\'/;s/\..*//g;s/^//;s/$//;s/\n//g"  ) )

if [[ $sysName != "" ]];then
location=$(snmpbulkwalk -t 1 -r 0 -v2c -c $community $host location 2> /dev/null | awk -F ": " '{print $2}' )
sysUpTimeInstance=$(snmpbulkwalk -t 1 -r 0 -v2c -c $community $host sysUpTimeInstance 2> /dev/null | awk -F ": " '{print $2}' )
serialNumber=$(snmpbulkwalk -t 1 -r 0 -v2c -c $community $host SNMPv2-SMI::mib-2.47.1.1.1.1.11.1001 2> /dev/null | awk -F ": " '{print $2}' ) 
fi
echo "Name: ${sysName}"
  echo "Location: $location"
  echo "Uptime: $sysUpTimeInstance"
  echo "serialNumber: $serialNumber"


  exit 0
