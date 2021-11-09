#!/usr/bin/env bash


FOLDERS=( "adm" "dotfiles" ".vim" "public_html" "sounds" ".gkrellm2" "wallpaper" "wallpaper1" ".ssh" ".gnupg" ".gnupg" "Music")

#for f in "${FOLDERS[*]}"; do printf "%s  \" \" ON \ \n" $f; done

check_folders(){
    myfolders=$(for f in "${FOLDERS[*]}"; do printf "%s  \" \" ON \ \n" $f; done)

    echo -e "$myfolders"

    folders=$(whiptail --backtitle "CHOOSE DIRECTORIES" --title "Choose directories to copy" --checklist \
    "Choose Folder Options:" 20 78 13 \
    $(echo -e $myfolders) 3>&1 1>&2 2>&3 )


    echo "$folders"
}
    #"adm" " " ON \
    #"dotfiles" " " ON \
    #".vim" " " ON \
    #"public_html" " " ON \
    #"sounds" " " ON \
    #".gkrellm2" " " ON \
    #"wallpaper" " " ON \
    #"wallpaper1" " " ON \
    #"bin" " " ON \
    #".ssh" " " ON \
    #".gnupg" " " ON \
    #"Music" " " OFF 3>&1 1>&2 2>&3 )

    #"$(echo $myfolders)" 3>&1 1>&2 2>&3 )

check_folders
