#!/usr/bin/env bash


FOLDERS=( "adm" "dotfiles" ".vim" "public_html" "sounds" ".gkrellm2" "wallpaper" "wallpaper1" ".ssh" ".gnupg" ".gnupg" "Music")

check_folders(){
    myfolders=$(for f in "${FOLDERS[*]}"; do printf "%s  \" \" ON \ \n" $f; done)


    folders=$(whiptail --title "Choose directories to copy" --backtitle "CHOOSE DIRECTORIES" --checklist \
    "Choose Folder Options:" 20 78 13 \
    "adm" " " ON \
    "dotfiles" " " ON \
    ".vim" " " ON \
    "public_html" " " ON \
    "sounds" " " ON \
    ".gkrellm2" " " ON \
    "wallpaper" " " ON \
    "wallpaper1" " " ON \
    "bin" " " ON \
    ".ssh" " " ON \
    ".gnupg" " " ON \
    "Music" " " OFF 3>&1 1>&2 2>&3 )

}
