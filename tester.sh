#!/usr/bin/env bash

LOGFILE=/tmp/templogfile

password=$(whiptail --backtitle "SUDO PASSWORD CHECKER" --title "Check sudo with auto password" --passwordbox "Please enter your SUDO password" 8 78 3>&1 1>&2 2>&3 )


echo "$password" | sudo -u dsj --stdin pacman -Ss x11-ssh-askpass >$LOGFILE

whiptail --backtitle "HOW DID WE DO?" --title "Success or not?" --textbox $LOGFILE  40 78
