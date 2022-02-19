#!/bin/bash

function readkeys {
	escape_char=$(printf "\u1b")
	read -rsn1 mode # get 1 character
	if [[ $mode == $escape_char ]]; then
	    read -rsn2 mode # read 2 more chars
	fi
	case $mode in
	    'q'    ) echo QUITTING ; cont=false;exit ;;
	    '[A'   ) echo UP ;;
	    '[B'   ) echo DN ;;
	    '[D'   ) echo LEFT ;;
	    '[C'   ) echo RIGHT ;;
	    +[1-9] ) echo $mode ; cont=false ; exit ;;
	    *      ) >&2 echo 'ERR bad input'; cont=false;exit ;;
	esac
}
cont=true
while $cont; do
	readkeys
	case $mode in
		+[1-9]) echo $mode
			;;
	esac		
done
