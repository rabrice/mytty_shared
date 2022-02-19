#!/bin/bash

#test if dialog is installed

dialog --clear


DIALOG_CANCEL=1
DIALOG_ESC=255
DIALOG_SFTP=3
HEIGHT=0
WIDTH=70
PAGE_TITLE="Mytty -- Easy ssh access to linux boxes"
SSHCALL='/usr/bin/ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'


display_result() {
  dialog --title "$1" \
    --backtitle "Mytty assets easy access" \
    --no-collapse \
    --msgbox "$result" 0 0
}



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
		tmux new -s ${sess_name}_1 ${SSHCALL} ${CONN}
	else
		case $op in
			${opnbr[$op]} )
				tmux a -t  "${oplst[$op]}"
        			tmux_start $sess_name
				;;
			n|N )
				sn=$((maxsess+1))
				tmux new -s ${sess_name}_${sn} ${SSHCALL} ${CONN}	
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


progress_dialog(){
	exec 3>&1
	dialog --backtitle "${PAGE_TITLE}" --title "GAUGE" --gauge "Transfer in progress, please wait...!!" 10 40 0
	exec 3>&-
}


clear_dialog(){
	exec 3>&1
	dialog --backtitle "${PAGE_TITLE}" --infobox "$1" 0 0
	exec 3>&-
}


sftp_dialog(){
	exec 3>&1
	FILE=$(dialog \
		--backtitle "${PAGE_TITLE}" \
		--title "Please choose a file" \
		--stdout --title "Please choose a file to transfer" \
		--fselect $HOME/ 14 48)
	exec 3>&-
	clear
	result="The file ${FILE} will be trasferred to $1/tmp"
	display_result "Info"
	clear
	scp -q -o ConnectTimeout=5 ${FILE} $1:/tmp 2>${APPDIR}sftperror &
	sftpPID=$!
	PCT=10
	while ps | grep " ${sftpPID} " ; do
	   	if (( ${PCT} < 100 )); then
	    		PCT=$((PCT+10))
	    	else 
	    		PCT=10
	    	fi		
	
	    	(	 
	          cat <<EOF 
	          $PCT 
EOF
		) | progress_dialog 
		sleep 1	
	 	clear	
  	done	

	if wait ${sftpPID}; then
	        result="${FILE} was trasferred successfully \n to $1/tmp"
	        display_result 'INFO'
	
	else
	        sftpError=$(cat ${APPDIR}/sftperror)
	        result="ERROR -- ${sftpError}"
	        display_result 'INFO'
	fi	  

}
	


tmux_start_d(){
	sess_name=$1	
	TXSUBOPTIONS=()
	TXCONN=()
	txcount=1
	while read -r subm; do
	      TXSUBOPTIONS+=($txcount)
	      TXSUBOPTIONS+=("$subm")
	      TXCONN+=($conn)
	      #echo $subm >> ~/mytty_dialog/rafa.txt
	      txcount=$((txcount+1))
	done < <(tmux ls -F '#{session_name}'| grep -i "${sess_name}_" )
	if [ -z  ${tx_selection} ]; then
		tx_lastselection='1'
	else
		tx_lastselection=$tx_selection
	fi	
	TXSUBOPTIONS+=("N")
	TXSUBOPTIONS+=("New Session")
	exec 3>&1
	tx_selection=$(dialog \
		--backtitle "${PAGE_TITLE}" \
		--title "Tmux Sessions for $1 ($2)" \
		--clear \
		--default-item $tx_lastselection \
		--cancel-label "Back" \
		--extra-button \
		--extra-label 'Main'\
		--menu "Please select:" $HEIGHT $WIDTH $j \
		"${TXSUBOPTIONS[@]}" \
		2>&1 1>&3)
	tx_exit_status=$?
	exec 3>&-
	
}


paint_submenu(){
	SUBOPTIONS=()
	CONN=()
	subcount=1
	while read -r subm_o; do
		conn=$(echo ${subm_o}|awk '{print $NF}')
		subm=$(echo ${subm_o}|awk '{$NF=""; print $0}')
		sName=${conn//.}
		txc=$(tmux ls 2>/dev/null |grep -i ${sName}|wc -l)
		clear_dialog "Building menu...."
		#txc=$(ps -ef | grep -i ${sName} | grep -v grep| wc -l)
		SUBOPTIONS+=($subcount)
		if (( txc == 0 )); then
			SUBOPTIONS+=("${subm}")
		else
			SUBOPTIONS+=("(${txc})*$subm")
		fi		
		CONN+=($conn)
		#echo $subm >> ~/mytty_dialog/rafa.txt
		subcount=$((subcount+1))
	done <<< "$(cat ${APPDIR}${SRVS}$1 |egrep -v '^#')"
	if [ -z  ${sub_selection} ]; then
		sub_lastselection='1'
	else
		sub_lastselection=$sub_selection
	fi	
	exec 3>&1
	sub_selection=$(dialog \
		--backtitle "${PAGE_TITLE}" \
		--title "Submenu $1" \
		--clear \
		--default-item $sub_lastselection \
		--cancel-label "Back" \
		--menu "Please select:" $HEIGHT $WIDTH $j \
		"${SUBOPTIONS[@]}" \
		2>&1 1>&3)
	sub_exit_status=$?
	exec 3>&-
}


paint_menu() {
	j=1
	OPTIONS=()
	for i in `ls ${APPDIR}${SRVS} |grep -v '.tmp'`; do
	   OPTIONS+=($j)
	   OPTIONS+=($i)
	   j=$((j+1))
	done
	if [ -z  ${selection} ]; then
		lastselection='1'
	else
	      lastselection=$selection
	fi	
	exec 3>&1
	selection=$(dialog \
		--backtitle "${PAGE_TITLE}" \
		--title "Main Menu" \
		--clear \
		--default-item $lastselection \
		--cancel-label "Exit" \
		--menu "Please select:" $HEIGHT $WIDTH $j \
		"${OPTIONS[@]}" \
		2>&1 1>&3)
	exit_status=$?
	exec 3>&-
}

##############
# MAIN
##############


clear

DIR="$(dirname "$(readlink -f "$0")")"
APPDIR="${DIR}/"
SRVS="servers/"
exit_status=0
sub_exit_status=0
tx_exit_status=0
while (( $exit_status == 0  )); do
	paint_menu
	
	sub_exit_status=0
	if (( $exit_status == $DIALOG_CANCEL )) || (( $exit_status == $DIALOG_ESC )); then clear; exit; fi
	clear
	while (( $sub_exit_status == 0  )); do	
		paint_submenu ${OPTIONS[$((selection*2-1))]}
		clear
		if (( ${sub_exit_status} != ${DIALOG_CANCEL} && ${sub_exit_status} != ${DIALOG_SFTP} )); then
			tx_exit_status=0
			sessName=${CONN[sub_selection-1]//.}
			tmuxcount=$(tmux ls |grep -i ${sessName}|wc -l)
			result="$sessName -- $tmuxcount -- ${sub_selection} -- ${CONN[$((sub_selection-1))]} -- ${CONN[@]} "
			#display_result 'Check Point'
			if (( ${tmuxcount} > 0 ));then
				while (( ${tx_exit_status} == 0 )); do
					tmux_start_d ${sessName} "${SUBOPTIONS[$((sub_selection*2-1))]/\*/}"
					clear
					if (( ${tx_exit_status} != ${DIALOG_CANCEL} && ${tx_exit_status} != ${DIALOG_SFTP})); then
						
						if (( $tx_selection == 'N' )); then
							sn=$((txcount))
							tmux new -s ${sessName}_${sn} ${SSHCALL} ${CONN[$((sub_selection-1))]} #2>${APPDIR}rafa.txt
							#echo '1'>> ${APPDIR}rafa.txt
						else	
							sn=$(echo ${TXSUBOPTIONS[$((tx_selection*2-1))]})
							if (( $(tmux ls | grep ${sn} |wc -l) > 0 )); then
								tmux a -t ${sn} #2>${APPDIR}rafa.txt
							fi	
							clear
						fi
					else
						if (( ${tx_exit_status} == ${DIALOG_SFTP} )); then
							paint_menu
							if (( $exit_status == $DIALOG_CANCEL )) || (( $exit_status == $DIALOG_ESC )); then clear; exit; fi
						fi		
					fi	
				done	
			else	
				sn=$((tmuxcount+1))
				tmux new -s ${sessName}_${sn} ${SSHCALL} ${CONN[$((sub_selection-1))]} #2>./rafa.txt
				#echo '3'>> rafa.txt
				tmux_start_d ${sessName} ${SUBOPTIONS[$((sub_selection*2-1))]/\*/}
				clear
				if (( ${tx_exit_status} == ${DIALOG_SFTP} )); then
					paint_menu
					if (( $exit_status == $DIALOG_CANCEL )) || (( $exit_status == $DIALOG_ESC )); then clear; exit; fi 
				fi
			fi			
		else
			if (( ${sub_exit_status} == ${DIALOG_SFTP} )); then
			#	sftp_dialog ${CONN[sub_selection-1]}
			#	sub_exit_status=0
			paint_menu
			fi	
		fi
	done	
done	
clear
