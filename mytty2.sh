!#/bin/bash

# Programed by Rafael Briceno.
# 2011-2020
#
# Get the list of files containing the list on servers of each country
#
# Then builds the menu according to the number of files present.
#
# The file names must be in the ./servers directory in this format:
# 	<server name> <[user@]ip>
#
# Names can contain spaces, the connection has to be the last column.
# 
#

clear

function printsubmenu() {
  cat ${APPDIR}${SRVS}/$1
}

function printmainmenu() {
    expnd=$1
    jj=0
    for i in `( ls -1 ${APPDIR}${SRVS} |sort -f)` ;do 
        jj=$((jj+1)) 
        #echo $j $i
        printf "%2d %s\n" $jj $(echo $i | awk -F- '{print $1}')
        opls[$jj]=$jj 
        if [[ $expnd == $j ]]; then
            printsubmenu $i
        fi    
        #case $j in
        #            1) cond="$j" ;;
        #            *) cond="$cond|$j" ;;
        #esac
    done; #sleep 10
}

DIR="$(dirname "$(readlink -f "$0")")"

j=0;
APPDIR="/usr/local/bin/mytty/"
APPDIR="${DIR}/"
SRVS="servers/"
echo "*****************************************"
echo "        SSH access to Linux Boxes"
echo "*****************************************"
cond=""
printmainmenu
echo "*****************************************"
echo "x Exit"

read op
echo $op 
#sleep 5

case $op in
	"" ) ;;

	x|X ) exit ;;	
	
	+[1-$j]  )  a=${op:1}
                printmainmenu $a
            ;;

	${opls[$op]} ) 	serv=$(( ls -1 ${APPDIR}${SRVS} ) |sort -f |head -n $op |tail -n 1)
			echo "** Connecting to "$serv ${APPDIR}${SRVS}${serv}" **"
			#sleep 10
			${APPDIR}mytty_srv2.sh ${APPDIR}${SRVS}${serv}
			#read -p "Press any key to try again..."
			;;

	
	* 	)	echo "Not valid, only "$j" valid options"
			read -p "Press any key to try again..."
			j=0
			;;
esac
$0
