cat ./check_snmp_cdp-neighbor-fix-config.sh
#!/bin/sh
#
#---------------------------------------------#
# check_snmp_cdp-neighbor-fix-config.sh
#
# last modified by Håkan Hammarin 20160529

community=$1
host=$2


if [[ $# -lt '2' ]] ; then
  echo "Usage:"
  echo "$0 [snmp community] [device hostname/IP]"
  echo ""
  exit 3
fi

#if [ $action == "list" ] ; then


sysName=( $(snmpbulkwalk -t 1 -r 0 -v2c -c $community $host SNMPv2-MIB::sysName.0 | awk '{print toupper($0)}' | awk -F ": " '{print $2}' | sed "s/'/\'/;s/\..*//g;s/^//;s/$//;s/\n//g"  ) )

if [[ $sysName != "" ]];then
RemoteInterface=( $(snmpbulkwalk -t 1 -r 0 -v2c -Oqn -c $community $host .1.3.6.1.4.1.9.9.23.1.2.1.1.7 | awk -F "\"" '{print $2}' | sed "s/ /\-/g" ) )
DeviceType=( $(snmpbulkwalk -t 1 -r 0 -v2c -Oqn -c $community $host .1.3.6.1.4.1.9.9.23.1.2.1.1.8 | awk -F "\"" '{print $2}' | sed "s/ /\-/g" ) )
IfIndex=( $(snmpbulkwalk -t 1 -r 0 -v2c -Oqn -c $community $host .1.3.6.1.4.1.9.9.23.1.2.1.1.6 | awk -F "." '{print $16}') )
RemoteDevice=( $( snmpbulkwalk -t 1 -r 0 -v2c -Oqn -c $community $host .1.3.6.1.4.1.9.9.23.1.2.1.1.6 | awk -F "\"" '{print $2}' | awk -F "." '{print $1}') )
fi
echo "ssh ${sysName}"
echo "conf t"
echo "!"
for ((i=0; i<${#IfIndex[@]}; i++)); do
  ifDescr[$i]=$(snmpwalk -t 1 -r 0 -v2c -Oqn -c $community $host .1.3.6.1.2.1.2.2.1.2.${IfIndex[$i]}  | awk -F " " '{print $2}' | sed "s/ /\-/g" )
  location[$i]=$(snmpbulkwalk -t 1 -r 0 -v2c -Oqn -c $community ${RemoteDevice[$i]} location | awk -F " " '{print $2}' | sed "s/ /\-/g" )
#  echo "${sysName} : ${ifDescr[$i]} is connected to ${RemoteDevice[$i]} : ${RemoteInterface[$i]}  Device type:  ${DeviceType[$i]}"
  echo "!"
  echo "interface ${ifDescr[$i]}"
  echo "description TRK;${RemoteDevice[$i]};${RemoteInterface[$i]};${DeviceType[$i]};${location[$i]}"
  echo "exit"
  echo "!"
done
echo "archive"
echo "log config"
echo "logging enable"
echo "notify syslog contenttype plaintext"
echo "hidekeys"
echo "path tftp://10.xx.xx.xx/\$h-\$t.txt"
echo "write-memory"


echo "end"
echo "write"
echo "quit"
  exit 0
fi

