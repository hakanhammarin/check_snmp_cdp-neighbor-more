#!/bin/sh
#
#---------------------------------------------#
# check_snmp_cdp-neighbor.sh
# Last modified by Jake Paulus 20081004
#
# Usage:
# ./check_snmp_cdp-neighbors.sh [snmp community] [device hostname/IP] [neighbor name or 'list'] (count)
#
# The list argument is used list all cdp neighbors. The optional count parameters specifies how many
# physical links should exist between the host and the neighbor.
#
# Added Interfacename

community=$1
host=$2
action=$3
domainsuffix=net.intern.hoglandet.se

if [[ $4 -lt '1' ]] ; then
  count='1'
else
  count=$4
fi

if [[ $# -lt '3' ]] ; then
  echo "Usage:"
  echo "$0 [snmp community] [device hostname/IP] [neighbor name or 'list'] (count)"
  echo ""
  echo "The list argument is used list all cdp neighbors. The optional count"
  echo "parameters specifies how many physical links should exist between"
  echo "the host and the neighbor."
  exit 3
fi

if [ $action == "list" ] ; then


sysName=( $(snmpbulkwalk -t 1 -r 0 -v2c -c $community $host SNMPv2-MIB::sysName.0 | awk '{print toupper($0)}' | awk -F ": " '{print $2}' | sed "s/'/\'/;s/\..*//g;s/^//;s/$//;s/\n//g"  ) )

if [[ $sysName != "" ]];then
RemoteInterface=( $(snmpbulkwalk -t 1 -r 0 -v2c -Oqn -c $community $host .1.3.6.1.4.1.9.9.23.1.2.1.1.7 | awk -F "\"" '{print $2}' | sed "s/ /\-/g" ) )
DeviceType=( $(snmpbulkwalk -t 1 -r 0 -v2c -Oqn -c $community $host .1.3.6.1.4.1.9.9.23.1.2.1.1.8 | awk -F "\"" '{print $2}' | sed "s/ /\-/g" ) )
IfIndex=( $(snmpbulkwalk -t 1 -r 0 -v2c -Oqn -c $community $host .1.3.6.1.4.1.9.9.23.1.2.1.1.6 | awk -F "." '{print $16}') )
RemoteDevice=( $( snmpbulkwalk -t 1 -r 0 -v2c -Oqn -c $community $host .1.3.6.1.4.1.9.9.23.1.2.1.1.6 | awk -F "\"" '{print $2}' | awk -F "." '{print $1}') )
fi

for ((i=0; i<${#IfIndex[@]}; i++)); do
  ifDescr[$i]=$(snmpwalk -t 1 -r 0 -v2c -Oqn -c $community $host .1.3.6.1.2.1.2.2.1.2.${IfIndex[$i]}  | awk -F " " '{print $2}' | sed "s/ /\-/g" )
location[$i]=$(snmpbulkwalk -t 1 -r 0 -v2c -Oqn -c $community ${RemoteDevice[$i]}.$domainsuffix location 2> /dev/null | awk -F " " '{print $2}' | sed "s/ /\-/g" )
  echo "${sysName} : ${ifDescr[$i]} is connected to ${RemoteDevice[$i]} : ${RemoteInterface[$i]}  Device type:  ${DeviceType[$i]}  Location: ${location[$i]}"
done

  exit 0
fi

result=`snmpbulkwalk -v 2c -c $community $host .1.3.6.1.4.1.9.9.23.1.2.1.1.6 | grep -ic $action`

if [[ $result -eq $count ]] ; then
  # match was found
  echo "OK: $count link(s) up to $action"
  exit 0
elif [[ $result -gt '0' ]] ; then
  # One of multiple redundant links is down
  echo "Warning: $result links up - $count expected"
  exit 1
else
  # no neighbor matches description given
  echo "Critical: No link up to $action"
  exit 2
fi

