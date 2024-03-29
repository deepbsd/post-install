#!/usr/bin/env bash

# Run this script after system and desktop are already installed
# This is a text version of this script (no whiptail)

### VARIABLES ####
user=dsj
PERS_DIRECTORIES=( dwhelper Documents movies Downloads tmp build repos )
MY_DIRS=( .ssh adm .gnupg sounds .gkrellm2 bin public_html wallpaper wallpaper1 )
MUSIC_DIR=( Music )
declare -A CLONED_REPOS=( [dotfiles]="https://github.com/deepbsd/dotfiles.git" [paru]="https://aur.archlinux.org/paru.git" [nvm]="https://github.com/nvm-sh/nvm.git" )
MY_DOTFILES="${CLONED_REPOS[dotfiles]}"
PARU_REPO="${CLONED_REPOS[paru]}"
NVM_REPO="${CLONED_REPOS[nvm]}"
BASICS=( vlc libdvdread libdvdcss libdvdnav gkrellm mlocate fzf feh nitrogen )
DEV_STUFF=( nodejs ruby npm npm-check-updates gvim anaconda )
FAVES=( gnome-terminal-transparency mate-terminal google-chrome oranchelo-icon-theme-git xcursor-breeze )
OPTIONAL=( pamac-aur libreoffice-still aisleriot gparted slack-desktop \
    telegram-desktop galculator atril timeshift-bin virtualbox virtualbox-guest-iso \
    virtualbox-host-dkms ntfs-3g liquidctl timer-bin dmidecode )
## This is the remote hostname (to copy dirs from) make it global for script
whathost=""

#====================  FUNCTIONS  ========================

check_for_update(){
    sudo pacman -Syy
    sudo pacman -Syyu
}

check_install(){
    if $( sudo pacman -Qi $1 &>/dev/null ); then
        echo "$1 is already installed..."
        return 0
    else
        echo "$1 is NOT installed.."
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

check_dir(){
    if [ -d "/home/$user/$1" ]; then
        return 0
    else
        return 1
    fi
}

## PERSONAL DIRECTORIES AND RESOURCES
make_directories(){
    echo "Making personal subdirectories..."
    mkdir "${PERS_DIRECTORIES[@]}"
    for dir in "${PERS_DIRECTORIES[@]}"; do
        if check_dir $dir ; then
            continue
        else
            mkdir /home/$user/$dir
        fi
    done
    echo "Did the following directories get made?  ${PERS_DIRECTORIES[@]}"; read empty
}

get_hostname(){
    # Pick a host to get stuff from on the local network
    echo "Download home directory files from what host on network?"; read whathost
}

# get ssh keys...
get_keys(){

    [ -z $whathost ] && get_hostname

    [ -f $HOME/.ssh/id_rsa ] || scp -o StrictHostKeyChecking=no -r "$user"@"$whathost".lan:.ssh .

    # check progress of getting ssh keys
    echo "Did we get keys from $whathost ?"; read empty
}

# clone the latest dotfiles
clone_dotfiles(){
    echo "Ready to clone dotfiles?" ; read dotfiles
    git clone $MY_DOTFILES

    ( $? && echo "Dotfiles clone successful." ) || echo "Problem with dotfiles clone..."

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
    [ -z $whathost ] && get_hostname

    echo "Starting to recursively copy following directories:  ${MY_DIRS[@]}"
    for dir in "${MY_DIRS[@]}" ; do
        echo "recursively copying $dir ..."
        scp -o StrictHostKeyChecking=no -r "$user"@"$whathost".lan:"$dir" .
    done
}

# Copy Music directory from hostname
copy_music_dir(){
   #[ ! -z ${whathost} ] && get_hostname
   echo "What host do you want to download your Music directory from?"
   read music_host
   if [[ "$yesno" =~ 'y' ]] ; then
        scp -r "$user"@"${music_host}"/Music ~/.
   else
       echo "Skipping Music downloads..." && return 0
   fi
}

## INSTALL DVD SUPPORT, POWERLINE, GKRELLM, MLOCATE
install_basics(){
    echo "Installing $BASICS[@] if not already installed..."

    for f in "${BASICS[@]}"; do
        if check_install $f; then
            continue
        else
            echo -e "\n\nInstalling $f \n"
            sudo pacman -S $f
        fi
    done

}

## INSTALL DEV STUFF 
install_dev_stuff(){
    echo "Want to install dev_stuff? (ie ${DEV_STUFF[@]}) (y/n)?" 
    read yes_no
    if [[ "$yes_no" =~ 'y' ]] ; then
        echo -e "\nInstalling Dev Stuff:  ${DEV_STUFF[@]} \n"
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
    ln -sf ~/dotfiles/.bashrc $HOME/.
    ln -sf ~/dotfiles/.bash_profile $HOME/.
    ln -sf ~/dotfiles/.vim $HOME/.
    ln -sf ~/dotfiles/.vimrc $HOME/.
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
            #git clone https://github.com/nvm-sh/nvm.git  
            git clone "$NVM_REPO" .
            echo "\n NVM Installed!!"
            source $HOME/.nvm/nvm.sh && cd
            echo "\nnvm.sh sourced in this terminal..."
        else
            echo "NVM directory did NOT get created!!"
            sleep 4
            cd $HOME
            mkdir $HOME/.nvm
            cd $HOME/.nvm
            git clone "$NVM_REPO" .  && echo -e "\n NVM Installed!!"
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
    echo -e "\nInstalling paru: \n"
    [ -d $HOME/build ] || mkdir $HOME/build
    cd ~/build
    #git clone https://aur.archlinux.org/paru.git
    git clone "$PARU_REPO"
    cd paru
    makepkg -si
    ( echo $? && echo -e "\nParu successfully built.\n") || echo -e "\nProblem with building Paru!!!\n"
    cd  # return to $HOME
}

# GNOME TRANSPARENCY FORK FOR TERMINAL; ALSO ICONS, CURSORS, CHROME
add_faves(){
    echo "Installing ${FAVES[@]}:"    
    for pkg in "${FAVES[@]}"; do
        echo -e "\nLooking at $pkg \n"
        check_install "$pkg" || paru -S "$pkg"
    done
}

add_optional(){
    echo "Install ${OPTIONAL[@]}?"; read yesno
    if [[ "$yesno" =~ [yY] ]]; then
        for f in "${OPTIONAL[@]}"; do
          if  check_install "$f"; then
              echo -e "\n $f already installed \n"
              sleep 1
          else
              paru -S "$f"
          fi
        done
    else
        echo "Okay, moving on..."
    fi
}

desktop_menu(){
    clear
    
    echo -e "\n\nInstall More Desktops?\n\n"
    echo -e  "\tK)   KDE"
    echo -e  "\tX)   XFCE"
    echo -e  "\tG)   Gnome"
    echo -e  "\tI)   i3wm"
    echo -e  "\tM)   Mate"
    echo -e  "\tQ)   Qtile"
    echo -e  "\tE)   Exit"

    echo "Your Desktop?  ==> "; read choice

    case $choice in 
        "K") sudo pacman -S plasma plasma-wayland-session kde-applications ;;
        "X") sudo pacman -S xfce4 xfce4-goodies ;;
        "G") sudo pacman -S gnome gnome-tweaks ;;
        "I") sudo pacman -S i3-gaps i3status ;;
        "M") sudo pacman -S mate mate-extra ;;
        "Q") sudo pacman -S qtile ;;
        "E") echo -en "\nThanks for installing $choice!\n\n"; sleep 3; clear; return 0;;
    esac
}

main_menu(){

    # make some space before the menu
    echo -e "\n\n===> Welcome to Post-Install for brand new Archlinux systems! <===\n"
    
    PS3="Please enter your choice: "
    options=(   "update your system" "make directories" "get keys" "clone dotfiles" \
        "start ssh-agent" "start dir copy" "copy music dir" "bashrc copy" \
        "install basics" "install paru" "add faves" "install dev stuff" \
        "install nvm" "install optional" "install desktops" "quit" )

    select opt in "${options[@]}"
    do
        case $opt in 
            "update your system" ) check_for_update; break 1 ;;
            "make directories" ) make_directories; break 1 ;;
            "get keys" ) get_keys; break 1 ;;
            "clone dotfiles" ) clone_dotfiles; break 1 ;;
            "start ssh-agent" ) ssh_agent_start; break 1 ;;
            "start dir copy" ) start_dir_copy; break 1 ;;
            "copy music dir" ) copy_music_dir ; break 1 ;;
            "bashrc copy" ) copy_dotfiles; break 1 ;;
            "install basics" ) install_basics; break 1 ;;
            "install paru" ) install_paru; break 1 ;;
            "add faves" ) add_faves; break 1 ;;
            "install dev stuff" ) install_dev_stuff; break 1 ;;
            "install nvm" ) install_nvm; break 1 ;;
            "install optional" ) add_optional; break 1 ;; 
            "install desktops" ) desktop_menu; break 1 ;; 
            "quit" ) echo "Thanks for using POST-INSTALL!"; echo; exit 0 ;;
            * ) echo "invalid option" ;;
        esac
    done
}


## CAll MAIN_MENU
clear
while : ; do main_menu; done

