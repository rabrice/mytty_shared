#!/bin/bash

# Programed by Rafael Briceno.
# 2011-2012
#
# Receives the name of the file with the list of servevrs and build the menu.
#
# 
# Then based on user's selection stablish the ssh session.
# 
# 


clear
j=0; 
srvlist=$1
srvlist_title=`basename $1`

##############
# Select or create a tmux session
##############
tmux_start () {
	sess_name=$1
	o=0
	clear
	while read i; do
		o=$((o+1))
		if [ $o -eq 1 ]; then
			echo "-----------------------------------------------------"
			echo "       Select Session for $sess_name"
			echo "-----------------------------------------------------"
		fi
		echo "   $o $i"
		oplst[$o]=$(echo $i |awk -F: '{print $1}')
		opnbr[$o]=$o
	done < <(tmux ls| grep -i ${sess_name} )
	if [ $o -ne 0 ];then
		maxsess=$( echo ${oplst[$o]} |awk -F_ '{print $2}' )
		echo "---------------"
		echo 'n New Session'
		echo 'x Exit'
		read op
	fi	
	#sleep 10	
	if [ $o -eq 0 ]; then
		tmux new -s ${sess_name}_1 /usr/bin/ssh ${CONN}
	else
		case $op in
			${opnbr[$op]} )
				tmux a -t  "${oplst[$op]}"
        			tmux_start $sess_name
				;;
			n|N )
				sn=$((maxsess+1))
				tmux new -s ${sess_name}_${sn} /usr/bin/ssh ${CONN}	
       				tmux_start $sess_name
				;;
			x|X )
				return
				;;	
			* )
				#tmux a -t  "${sess_name}_${cwop}"
				read -p  "Not valid, only $o options"
				tmux_start $sess_name
				;;
		esac	
        fi
}


echo "************************************************************************"
echo "  	  		Select $srvlist_title"	
echo "************************************************************************"
#cat ${srvlist}
#sleep 15
nopc=$(wc -l $srvlist |awk '{print $1}')
nl=20
cond=""
> ${srvlist}_$$.tmp
while read i ; do
        j=$((j+1))
	#i=$(echo ${i} | awk '{$NF=""; print $0}')
	ip=$(echo ${i} | awk '{print $NF}')
	screen=''
	if [ $(tmux ls 2>/dev/null| grep ${ip//.} |wc -l) -ne 0 ]; then
		screen='*'
	fi	
	echo "${screen} $(echo ${i} | awk '{$NF=""; print $0}')" >> ${srvlist}_$$.tmp
	opsls[$j]=$j
        case $j in
                1) cond="$j" ;;
                *) cond="$cond|$j" ;;
        esac
done < <(grep -v '^$\|^\s*\#' ${srvlist})
#done < <(cat $srvlist)

srvlist_tmp="${srvlist}_$$.tmp"
if [ ${nopc} -gt ${nl} ]; then  
	cat ${srvlist_tmp} | pr -n" "3 -t -3
else
	cat ${srvlist_tmp} | pr -n" "3 -t -1
fi
rm ${srvlist_tmp}

echo "************************************************************************"

echo "x Exit"
usr=''
read op
case ${op} in

	"" ) ;;
	
	x|X ) exit ;;

	${opsls[$op]} )
		serv=$(head -n $op ${srvlist} |tail -n 1 | awk '{print $NF}')
		#usr=$(head -n $op ${srvlist} |tail -n 1 | awk '{print $3}')
		AT='@'
		if  echo "${serv}" |grep "${AT}"; then 
			CONN=${serv}
		else 
			CONN=${USER}@${serv}
		fi	
		echo "** Connecting to "${serv}" **"
		sess_name=${CONN//.}
		#tmux new -s ${sess_name} ssh ${CONN}
		tmux_start $sess_name		

		#read -p "Press any key to continue..."
		;;
	* )
		echo "Not valid, only "${j}" options"
		read -p "Press any key to try again..."
		j=0 
		;;

esac
$0 $srvlist
