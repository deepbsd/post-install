#!/usr/bin/env bash

# Run this script on Arch systems after desktop are already installed

##########################
### VARIABLES, ARRAYS ####
##########################
LOGFILE=/tmp/logfile
FOLDERS=( "adm" "dotfiles" ".vim" "public_html" "sounds" ".gkrellm2" "wallpaper" "wallpaper1" ".ssh" ".gnupg" ".gnupg" "Music")
NORMAL_PKGS=( gkrellm libdvdread libdvdcss libdvdnav mlocate fzf powerline powerline-fonts )
DEV_PKGS=( ruby nodejs npm npm-check-updates gvim mlocate )
CLONED_REPOS=( "https://github.com/deepbsd/dotfiles.git" "https://aur.archlinux.org/paru.git" "https://github.com/nvm-sh/nvm.git" )
AUR_PKGS=( anaconda gnome-terminal-transparency mate-terminal google-chrome oranchelo-icon-theme-git xcursor-breeze pamac-aur )

#####################
####  FUNCTIONS
#####################

# CREATE LOGFILE
create_logfile(){
    touch $LOGFILE
    echo "STARTING post_install.sh $date " &>$LOGFILE
}



### SHOW SOME REMINDERS ABOUT SYSTEM CHOICES

# HOMED REMINDER
homed_message(){
    homed_message=$(systemctl status systemd-homed)
    echo "=== homed_message ===" &>>$LOGFILE

    whiptail --title "Homed Status" --backtitle "HOMED-STATUS"  --msgbox "${homed_message}  


    Hit OK to Continue" 40 78
}

# PAMBASE REMINDER
pambase_reminder(){
    echo "=== pambase_message ===" &>>$LOGFILE
    whiptail --title "Pambase Reminder" --backtitle "PAMBASE REMINDER"  --msgbox "Remember to enable systemd-homed as root or sudo may not work correctly.  

    Also, reinstall pambase if necessary.  Hit OK to Continue."  10 78
}


####  START CREATING AND MOVING ASSETS

## DOTFILES DIRECTORY
cloning_dotfiles(){
    echo "=== Cloning dotfiles ===" &>>$LOGFILE

    # adjust as necessary
    MY_DOTFILES="https://github.com/deepbsd/dotfiles.git"
    DOTFILE_URL=$(whiptail --title "Set DOTFILE REPO" --inputbox "Your Dotfile URL is $MY_DOTFILES  Change if necessary."\
--backtitle "SET DOTFILE REPO URL" 3>&1 1>&2 2>&3)

    if $(whiptale --title "Replace DOTFILE URL?" --backtitle "REPLACE DOTFILE URL" --yesno \
        "Replace $MY_DOTFILES with $DOTFILE_URL ?" 10 78 3>&1 1>&2 2>&3); then
        MY_DOTFILES="$DOTFILE_URL"
    else
        sleep 1
    fi

    if $(whiptail --title "Personal Directories and dotfiles..." --backtitle "Installing and Cloning Personal Customized
        Directories" --yesno "Do you want to create your personal files and folders?"  10 78 3>&1 1>&2 2>&3); then
        cd ~
        mkdir tmp repos build  &>>$LOGFILE
        git clone "$MY_DOTFILES" &>>$LOGFILE

        sleep 2
    else
        TERM=ansi whiptail --title "Moving on..." --backtitle "FILES NOT CREATED" --infobox "Not creating personal files and directories..." 8 78
        sleep 2
    fi
}


# CREATE AND COPY HOME DIRS
create_homedirs(){

    echo "=== Creating and Copying Home Directories ===" &>>$LOGFILE

    # THESE DIRECTORIES ARE STANDARD FOR MY HOME DIRECTORIES ON ALL MY SYSTEMS
    if $(whiptail --backtitle "COPYING DIRECTORIES" --title "Copying Directories to Home Folder"\
        --yesno "Copy directories to home $HOME?"  10 78 3>&1 1>&2 2>&3); 
    then

        # CHOOSE HOST ON NETWORK TO DOWNLOAD FILES AND DIRS FROM
        host=$(whiptail --backtitle "CHOOSE HOSTNAME" --title "Enter hostname to download from:" \
        --inputbox "What host to download directories from?"  10 40 3>&1 1>&2 2>&3)

        #myfolders=$(for f in "${FOLDERS[*]}"; do printf "%s  \" \" ON \ \n" $f; done)


        # CHOOSE FOLDERS TO COPY
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

        # CREATE AND COPY HOMEDIRS (Replace each space with a comma between dir names)
        homedirs=$( echo "${folders}" | sed -e 's/\"//g' | sed -e 's/ /,/g' )
        scp -o StrictHostKeyChecking=no -r dsj@"$host".lan:{"$homedirs"} .
        ##scp -Br dsj@"$whathost".lan:{adm,dotfiles,.vim,public_html,sounds,.gkrellm2,wallpaper,wallpaper1,bin,.ssh,.gnupg,Music} .
        sleep 2

    else
        TERM=ansi whiptail --backtitle "NOT COPYING DIRS NOW" --title "Not Copying Directories Now"  --infobox "Not copying directories now..." 10 78
        sleep 2
    fi
}


# LINK THE DOTFILES
link_dotfiles(){
    echo "=== Linking dotfiles in $HOME ===" &>>$LOGFILE
    if $(whiptail --backtitle "LINKING DOTFILES..." --title "Backing Up and Linking Dotfiles" --yesno "Backing up .bashrc.orig .bash_profile.orig .vimrc.orig and linking new dotfiles to cloned masters"  10 78 3>&1 1>&2 2>&3); 
    then
        cp ~/.bashrc ~/.bashrc.orig  &>>$LOGFILE
        cp ~/.bash_profile ~/.bash_profile.orig &>>$LOGFILE
        ln -sf ~/dotfiles/.bashrc .   &>>$LOGFILE
        ln -sf ~/dotfiles/.bash_profile .  &>>$LOGFILE
        ln -sf ~/dotfiles/.vimrc .  &>>$LOGFILE
        sleep 2
    else
        TERM=ansi whiptail --backtitle "NOT CREATING DOTFILES NOW" --title "Not Creating Dotfiles Now"  --infobox "NOT Creating Dotfiles now" 10 78
        sleep 2
    fi
}


# SSH-AGENT SERVICE
ssh_agent_service(){
    echo "=== Starting SSH_AGENT service; Adding secret key to SSH-AGENT ===" &>>$LOGFILE
    TERM=ansi whiptail --backtitle "ADD SSH KEY TO AGENT" --title "Adding your ssh secret key" \
    --infobox "Starting your SSH service and Adding your SSH key to ssh-agent. 

    Please enter your ssh passphrase: "  10 78

    [[ -f ~/.ssh/id_rsa ]] && eval $(ssh-agent) 2&>/dev/null

    ## NOTE: ADD CHECK FOR SSH_ASKPASS PROGRAM BEFORE THIS

    export SSH_ASKPASS=/usr/lib/ssh/x11-ssh-askpass
    export SSH_ASKPASS_REQUIRE="prefer"
    ssh-add ~/.ssh/id_rsa  &>/tmp/ssh-message

    TERM=ansi whiptail --title "Adding your ssh-key to ssh-agent" --infobox "Adding your ssh secret key to running ssh-agent..." 10 78
    sleep 2

    whiptail --backtitle "SSH-ADD STATUS" --title "Status for ssh-add command: " --textbox /tmp/ssh-message  10 78
}



# INSTALL MYSTUFF
install_mystuff(){
    echo "=== Installing gkrellm, libdvdread, libdvdcss, libdvdnav, mlocate, fzf, powerline, powerline-fonts ===" &>>$LOGFILE
    if $(whiptail --backtitle "INSTALL MYSTUFF" --title "Install Mystuff?"  \
        --yesno "Install Gkrellm, DVD support, Mlocate, and fzf?" 10 78 3>&1 1>&2 2>&3)
    then
        ## SYNC PACMAN DBs
        sudo pacman -Syy  &>>$LOGFILE

        ## INSTALL GKRELLM, DVD SUPPORT, MLOCATE FUZZY FILEFINDER
        $(which gkrellm &>/dev/null) || sudo pacman -S gkrellm &>>$LOGFILE
        sudo pacman -S libdvdread libdvdcss libdvdnav mlocate fzf  &>>$LOGFILE
        sudo updatedb  &>>$LOGFILE

        ## INSTALL POWERLINE
        $(which powerline >/dev/null) || sudo pacman -S powerline powerline-fonts &>>$LOGFILE

    else
        term=ANSI  whiptail --backtitle "MYSTUFF NOT INSTALLED NOW" --title "Mystuff not install now" --infobox "Will have to install Mystuff later on" 10 78
        sleep 2

    fi
}


## INSTALL POWERLINE AND DEV STUFF 
install_devstuff(){
    echo "=== Installing ruby, nodejs, npm, npm-check-updates, gvim, mlocate ===" &>>$LOGFILE
    if $(whiptail --backtitle "INSTALL DEVSTUFF" --title "Install Devstuff?"  --yesno "Install Ruby, node, npm, gvim, npm-check-updates?" 10 78 3>&1 1>&2 2>&3)
    then
        sudo pacman -S  ruby nodejs npm npm-check-updates gvim mlocate  &>>$LOGFILE
    else
        term=ANSI  whiptail --backtitle "DEVSTUFF NOT INSTALLED NOW" --title "Devstuff not installed now" --infobox "Will have to install Devstuff later on" 10 78
        sleep 2
    fi
}


# NVM
install_nvm(){
    ## YESNO TO INSTALL NVM
    echo "=== Install NVM shell script ===" &>>$LOGFILE
    if $(whiptail --backtitle "INSTALL NVM" --title "Install NVM?"  --yesno "Install NVM?" 10 78 3>&1 1>&2 2>&3)
    then
        mkdir $HOME/.nvm
        [[ -x $(which git &>/dev/null) ]] && cd && git clone https://github.com/nvm-sh/nvm.git .nvm/. &>>$LOGFILE
        [[ -d ~/.nvm ]] && cd ~/.nvm && source nvm.sh && cd  &>>$LOGFILE
    else
        term=ANSI  whiptail --backtitle "NVM NOT INSTALLED NOW" --title "NMV not install now" --infobox "Will have to install NVM later on" 10 78
        sleep 2
    fi
}



## INSTALL PARU (THE AUR HELPER)
install_paru(){
    echo "=== Clone and install paru ===" &>>$LOGFILE
    if $(whiptail --backtitle "INSTALL PARU" --title "Install Paru?"  --yesno "Install Paru?" 10 78 3>&1 1>&2 2>&3)
    then
        if [ ! $(( which paru &>/dev/null )) ]; then
            cd ~/build
            git clone https://aur.archlinux.org/paru.git &>>$LOGFILE
            cd paru
            makepkg -si   &>>$LOGFILE
            cd
        fi
    else
        term=ANSI  whiptail --backtitle "PARU NOT INSTALLED NOW" --title "Paru not install now" --infobox "Will have to install Paru later on" 10 78
        sleep 2
    fi
}



## CHECK ANACONDA
install_anaconda(){
    echo "=== Clone and install anaconda ===" &>>$LOGFILE
    if $(whiptail --backtitle "INSTALL ANACONDA" --title "Install Anaconda?"  --yesno "Install Anaconda?" 10 78 3>&1 1>&2 2>&3)
    then
        [[ -f /opt/anaconda/bin/anaconda-navigator ]] || paru -S anaconda
    else
        term=ANSI  whiptail --backtitle "ANACONDA NOT INSTALLED NOW" --title "Anaconda not install now" \
            --infobox "Will have to install Anaconda later on" 10 78
        sleep 2
    fi
}


# FAVORITES FROM AUR
install_aur_goodies(){
    echo "=== Clone and install gnome-terminal-transparency, mate-terminal, pamac-aur, google-chrome, oranchelo-icons, xcursor-breeze ===" &>>$LOGFILE
    if $(whiptail --backtitle "INSTALL AUR GOODIES" --title "Install Chrome, gnome-terminal-transparency, mate-terminal, oranchelo icons, xcursor-breeze, pamac-aur?"  --yesno "Install Aur Goodies?" 10 78 3>&1 1>&2 2>&3)
    then
        paru -S gnome-terminal-transparency mate-terminal 
        paru -S google-chrome oranchelo-icon-theme-git xcursor-breeze pamac-aur
    else
        term=ANSI  whiptail --backtitle "NOT INSTALLED AUR GOODIES NOW" --title "Not installing AUR goodies now" --infobox "Will have to install AUR Goodies later on" 10 78
        sleep 2
    fi
}

###################################
########      MAIN     ############
###################################

main(){
    create_logfile
    homed_message
    pambase_reminder
    cloning_dotfiles
    create_homedirs
    link_dotfiles
    ssh_agent_service
    install_mystuff
    install_devstuff
    install_nvm
    install_paru
    install_anaconda
    install_aur_goodies
}

### START HERE

#main
create_homedirs


