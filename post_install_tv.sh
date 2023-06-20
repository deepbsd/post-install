#!/usr/bin/env bash

# Run this script after system and desktop are already installed

### VARIABLES ####
user=dsj
PERS_DIRECTORIES=( tmp build repos )
MY_DIRS=( .ssh adm .vim .gnupg sounds .gkrellm2 bin public_html wallpaper wallpaper1 )
MUSIC_DIR=( Music )
MY_DOTFILES="https://github.com/deepbsd/dotfiles.git"
BASICS=( vlc libdvdread libdvdcss libdvdnav gkrellm mlocate fzf )
DEV_STUFF=( nodejs ruby npm npm-check-updates gvim anaconda )
FAVES=( gnome-terminal-transparency mate-terminal google-chrome oranchelo-icon-theme-git xcursor-breeze )
OPTIONAL=( pamac-aur libreoffice-still aisleriot gparted )
## This is the remote hostname (to copy dirs from) make it global for script
whathost=""


check_install(){
    if $( paru -Qi $1 &>/dev/null ); then
        return 0
    else
        return 1
    fi
}

# get status of systemd-homed
systemd_homed_status(){
    systemctl status systemd-homed
    echo "Be sure to start and enable systemd-homed (as root) or else sudo may not work properly"
    echo "Also, reinstall pambase if necessary `pacman -S pambase`"
    echo "Type any to continue..." ; read empty
}

## PERSONAL DIRECTORIES AND RESOURCES
make_directories(){
    echo "Making personal subdirectories..."
    mkdir "${PERS_DIRECTORIES[@]}"
    echo "Did the following directories get made?  ${PERS_DIRECTORIES[@]}"; read empty

    # Pick a host to get stuff from on the local network
    echo "Download home directory files from what host on network?"; read whathost
}

# get ssh keys...
get_keys(){
    [ -f $HOME/.ssh/id_rsa ] || scp -o StrictHostKeyChecking=no -r "$user"@"$whathost".lan:.ssh .

    # check progress of getting ssh keys
    echo "Did we get keys from $whathost ?"; read empty
}

# clone the latest dotfiles
clone_dotfiles(){
    echo "Ready to clone dotfiles?" ; read dotfiles
    git clone $MY_DOTFILES

    ( $? && echo "Dotfiles clone successful." ) || echo "Problem with dotfiles clone..."

    #scp -o StrictHostKeyChecking=no -r "$suer"@"$whathost".lan:{adm,dotfiles,.vim,public_html,sounds,.gkrellm2,wallpaper,wallpaper1,bin,.ssh,.gnupg,Music} .
    #scp -Br "$suer"@"$whathost".lan:{adm,.vim,public_html,sounds,.gkrellm2,wallpaper,wallpaper1,bin,.gnupg,Music} .
}

# SSH-AGENT SERVICE
ssh_agent_start(){
    echo "Start the ssh-agent service..."
    eval $(ssh-agent)
    ls ~/.ssh/* ; echo "Add which key? "; read key_name
    ssh-add ~/.ssh/"$key_name"

}

# Start dir copy
start_dir_copy(){
echo "Starting to recursively copy following directories:  ${MY_DIRS[@]}"
    for dir in "${MY_DIRS[@]}" ; do
        echo "recursively copying $dir ..."
        scp -o StrictHostKeyChecking=no -r "$user"@"$whathost".lan:$dir .
    done
}

# Copy Music directory from hostname
copy_music_dir(){
   [[ -z ${whathost} ]] && return 0
   echo "Want to download big Music directory from ${whathost}? (y/n)"
   read yesno
   if [[ "$yesno" =~ 'y' ]] ; then
        scp -r "$user"@"${whathost}"/Music ~/.
   else
       echo "Skipping Music downloads..." && return 0
   fi
}

## INSTALL DVD SUPPORT, POWERLINE, GKRELLM, MLOCATE
install_basics(){
    echo "Installing $BASICS and powerline and gkrellm..."
    sudo pacman -S ${BASICS[@]}
    echo "updating locate database..."
    sudo updatedb

    ## INSTALL POWERLINE
    echo "Install powerline if not already installed."
    check_install powerline || sudo pacman -S powerline powerline-fonts

    ## CHECK FOR OLD FAITHFULS
    echo "Install gkrellm if not already installed."
    check_install gkrellm || sudo pacman -S gkrellm

}

## INSTALL DEV STUFF 
install_dev_stuff(){
    echo "Want to install dev_stuff? (ie ${DEV_STUFF[@]}) (y/n)?" 
    read yes_no
    if [[ "$yes_no" =~ 'y' ]] ; then
        echo "Installing Dev Stuff:  ${DEV_STUFF[@]}"
        for f in ${DEV_STUFF[@]}; do
            check_install "$f" || sudo pacman -S $f
        done
    else
        echo "Skipping dev_stuff..." && return 0
    fi

}

## DOTFILES
copy_dotfiles(){
    echo "Link dotfiles from cloned dotfiles repo..."
    cp ~/.bashrc ~/.bashrc.orig
    cp ~/.bash_profile ~/.bash_profile.orig
    ln -sf ~/dotfiles/.bashrc .
    ln -sf ~/dotfiles/.bash_profile .
    ln -sf ~/dotfiles/.vimrc .
}

# NVM
install_nvm(){
    echo "Want to install nvm? " && read nvm_yesno
    if [[ "$nvm_yesno" =~ 'y' ]] ; then
        echo "Create NVM clone..."
        mkdir $HOME/.nvm
        ## [[ -x $(which git &>/dev/null) ]] && cd && git clone https://github.com/nvm-sh/nvm.git .nvm/.
        if [[ -d $HOME/.nvm ]]; then
            cd $HOME/.nvm 
            git clone https://github.com/nvm-sh/nvm.git  
            echo "\n NVM Installed!!"
            source $HOME/.nvm/nvm.sh && cd
            echo "\nnvm.sh sourced in this terminal..."
        else
            echo "NVM directory did NOT get created!!"
            sleep 4
            cd $HOME
            mkdir $HOME/.nvm
            cd $HOME/.nvm
            git clone https://github.com/nvm-sh/nvm.git  && echo "\n NVM Installed!!"
            cd
        fi

    else
        echo "Skipping install of nvm..."
        return 0
    fi
}


## INSTALL PARU  
install_paru(){
    $( check_install paru ) && echo "Paru already installed!!" && sleep 4 && return 0
    echo "Installing paru: "
    [ -d $HOME/build ] || mkdir $HOME/build
    cd ~/build
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si
    ( echo $? && echo "Paru successfully built.") || echo "Problem with building Paru!!!"
    cd  # return to $HOME
}

# GNOME TRANSPARENCY FORK FOR TERMINAL; ALSO ICONS, CURSORS, CHROME
add_faves(){
    echo "Installing ${FAVES[@]}:"    
    for pkg in "${FAVES[@]}"; do
        check_install "$pkg" || paru -S "$pkg"
    done
}

add_optional(){
    echo "Install ${OPTIONS[@]}?"; read yesno
    if [[ "$yesno" =~ [yY] ]]; then
        for f in "${OPTIONS[@]}"; do
            check_install "$f"
        done
    else
        echo "Okay, moving on..."
    fi
}


main_menu(){

    # Not sure if we still need this
    systemd_homed_status


    PS3="Please enter your choice: "
    options=( "make directories" "get keys" "clone dotfiles" "start ssh-agent" "start dir copy" "bashrc copy" \
        "install basics" "install paru" "add faves" "install dev stuff" "install nvm" "install optional" "quit" )

    select opt in "${options[@]}"
    do
        case $opt in 
            "make directories" ) make_directories ;;
            "get keys" ) get_keys ;;
            "clone dotfiles" ) clone_dotfiles ;;
            "start ssh-agent" ) ssh_agent_start ;;
            "start dir copy" ) start_dir_copy ;;
            "bashrc copy" ) copy_dotfiles ;;
            "install basics" ) install_basics ;;
            "install paru" ) install_paru ;;
            "add faves" ) add_faves ;;
            "install dev stuff" ) install_dev_stuff ;;
            "install nvm" ) install_nvm ;;
            "install optional" ) add_optional ;; 
            "quit" ) break ;;
            * ) echo "invalid option" ;;
        esac
    done


}

# MAIN  (We'll delete this eventually...)
main(){
    systemd_homed_status
    make_directories
    get_keys
    clone_dotfiles
    ssh_agent_start
    start_dir_copy
    copy_dotfiles
    copy_music_dir
    install_basics
    install_paru
    add_faves
    install_dev_stuff
    install_nvm
    add_optional
}

## CAll MAIN
main_menu

