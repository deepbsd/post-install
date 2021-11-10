#!/usr/bin/env bash

password=$(whiptail --backtitle "SUDO PASSWORD CHECKER" --title "Check sudo with auto password" --passwordbox "Please enter your SUDO password" 8 78 3>&1 1>&2 2>&3 )

#echo "$password"

echo "$password" | sudo -u dsj --stdin pacman -Ss x11-ssh-askpass
