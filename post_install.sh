#!/usr/bin/env bash

# Run this script after system and desktop are already installed

homed_message=$(systemctl status systemd-homed)

# CREATE LOGFILE
LOGFILE=/tmp/logfile
touch $LOGFILE

# HOMED REMINDER
whiptail --title "Homed Status" --backtitle "HOMED-STATUS"  --msgbox "${homed_message}  


Hit OK to Continue" 40 78

# PAMBASE REMINDER
whiptail --title "Pambase Reminder" --backtitle "PAMBASE REMINDER"  --msgbox "Remember to enable systemd-homed as root or sudo may not work correctly.  

Also, reinstall pambase if necessary.  Hit OK to Continue."  10 78

# FUNCTION: Create home directories and clone everyday repos
create_clone(){
    cd ~
    mkdir tmp repos build  &>>$LOGFILE
    git clone https://github.com/deepbsd/dotfiles.git &>>$LOGFILE
}


## PERSONAL DIRECTORIES AND RESOURCES
if $(whiptail --title "Personal Directories and dotfiles..." --backtitle "Installing and Cloning Personal Customized
    Directories" --yesno "Do you want to create your personal files and folders?"  10 78 3>&1 1>&2 2>&3); then

    create_clone
    sleep 2
else
    TERM=ansi whiptail --title "Moving on..." --backtitle "FILES NOT CREATED" --infobox "Not creating personal files and directories..." 8 78
    sleep 2
fi

# CHOOSE HOST ON NETWORK TO DOWNLOAD FILES AND DIRS FROM
host=$(whiptail --backtitle "CHOOSE HOSTNAME" --title "Enter hostname to download from:" \
--inputbox "What host to download directories from?"  10 40 3>&1 1>&2 2>&3)


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



# CREATE AND COPY HOMEDIRS
homedirs=$( echo "${folders}" | sed -e 's/\"//g' | sed -e 's/ /,/g' )

create_homedirs(){
    scp -o StrictHostKeyChecking=no -r dsj@"$host".lan:{"$homedirs"} .
    ##scp -Br dsj@"$whathost".lan:{adm,dotfiles,.vim,public_html,sounds,.gkrellm2,wallpaper,wallpaper1,bin,.ssh,.gnupg,Music} .
    sleep 2
}

if $(whiptail --backtitle "COPYING DIRECTORIES" --title "Copying Directories to Home Folder" --yesno "Copy directories to home $HOME?"  10 78 3>&1 1>&2 2>&3); 
then
    create_homedirs
    sleep 2
else
    TERM=ansi whiptail --backtitle "NOT COPYING DIRS NOW" --title "Not Copying Directories Now"  --infobox "Not copying directories now..." 10 78
    sleep 2
fi


# DOTFILES
do_dotfiles(){
    cp ~/.bashrc ~/.bashrc.orig  &>>$LOGFILE
    cp ~/.bash_profile ~/.bash_profile.orig &>>$LOGFILE
    ln -sf ~/dotfiles/.bashrc .   &>>$LOGFILE
    ln -sf ~/dotfiles/.bash_profile .  &>>$LOGFILE
    ln -sf ~/dotfiles/.vimrc .  &>>$LOGFILE
    sleep 2
}

if $(whiptail --backtitle "LINKING DOTFILES..." --title "Backing Up and Linking Dotfiles" --yesno "Backing up .bashrc.orig .bash_profile.orig .vimrc.orig and linking new dotfiles to cloned masters"  10 78 3>&1 1>&2 2>&3); 
then
    do_dotfiles
    sleep 2
else
    TERM=ansi whiptail --backtitle "NOT CREATING DOTFILES NOW" --title "Not Creating Dotfiles Now"  --infobox "NOT Creating Dotfiles now" 10 78
    sleep 2
fi



# SSH-AGENT SERVICE
TERM=ansi whiptail --backtitle "ADD SSH KEY TO AGENT" --title "Adding your ssh secret key" \
--infobox "Starting your SSH service and Adding your SSH key to ssh-agent. 

Please enter your ssh passphrase: "  10 78

[[ -f ~/.ssh/id_rsa ]] && eval $(ssh-agent) 2&>/dev/null

export SSH_ASKPASS=/usr/lib/ssh/x11-ssh-askpass
export SSH_ASKPASS_REQUIRE="prefer"
ssh-add ~/.ssh/id_rsa  &>/tmp/ssh-message

TERM=ansi whiptail --title "Adding your ssh-key to ssh-agent" --infobox "Adding your ssh secret key to running \
ssh-agent..." 10 78

sleep 1

whiptail --backtitle "SSH-ADD STATUS" --title "Status for ssh-add command: " --textbox /tmp/ssh-message  10 78

# INSTALL MYSTUFF
install_mystuff(){
    ## SYNC PACMAN DBs
    sudo pacman -Syy  &>>$LOGFILE

    ## INSTALL GKRELLM, DVD SUPPORT, MLOCATE FUZZY FILEFINDER
    $(which gkrellm &>/dev/null) || sudo pacman -S gkrellm &>>$LOGFILE
    sudo pacman -S libdvdread libdvdcss libdvdnav mlocate fzf  &>>$LOGFILE
    sudo updatedb  &>>$LOGFILE

    ## INSTALL POWERLINE
    $(which powerline >/dev/null) || sudo pacman -S powerline powerline-fonts &>>$LOGFILE
}

# YESNO FOR CALLING INSTALL MYSTUFF
if $(whiptail --backtitle "INSTALL MYSTUFF" --title "Install Mystuff?"  --yesno "Install Gkrellm, DVD support, Mlocate, and fzf?" 10 78 3>&1 1>&2 2>&3)
then
    install_mystuff
else
    term=ANSI  whiptail --backtitle "MYSTUFF NOT INSTALLED NOW" --title "Mystuff not install now" --infobox "Will have to install Mystuff later on" 10 78
    sleep 2

fi

## INSTALL POWERLINE AND DEV STUFF 
install_devstuff(){
    sudo pacman -S  ruby nodejs npm npm-check-updates gvim mlocate  &>>$LOGFILE
}


## YESNO TO INSTALL DEV STUFF
if $(whiptail --backtitle "INSTALL DEVSTUFF" --title "Install Devstuff?"  --yesno "Install Ruby, node, npm, gvim, npm-check-updates?" 10 78 3>&1 1>&2 2>&3)
then
    install_devstuff
else
    term=ANSI  whiptail --backtitle "DEVSTUFF NOT INSTALLED NOW" --title "Devstuff not install now" --infobox "Will have to install Devstuff later on" 10 78
    sleep 2
fi

exit

# NVM
install_nvm(){
    mkdir $HOME/.nvm
    [[ -x $(which git &>/dev/null) ]] && cd && git clone https://github.com/nvm-sh/nvm.git .nvm/. &>>$LOGFILE
    [[ -d ~/.nvm ]] && cd ~/.nvm && source nvm.sh && cd  &>>$LOGFILE
}

## YESNO TO INSTALL NVM
if $(whiptail --backtitle "INSTALL NVM" --title "Install NVM?"  --yesno "Install NVM?" 10 78 3>&1 1>&2 2>&3)
then
    install_nvm
else
    term=ANSI  whiptail --backtitle "NVM NOT INSTALLED NOW" --title "NMV not install now" --infobox "Will have to install NVM later on" 10 78
    sleep 2
fi


## INSTALL PARU  
install_paru(){
    if [ ! $(( which paru &>/dev/null )) ]; then
        cd ~/build
        git clone https://aur.archlinux.org/paru.git &>>$LOGFILE
        cd paru
        makepkg -si   &>>$LOGFILE
        cd
    fi
}

## YESNO TO INSTALL PARU
if $(whiptail --backtitle "INSTALL PARU" --title "Install Paru?"  --yesno "Install Paru?" 10 78 3>&1 1>&2 2>&3)
then
    install_paru
else
    term=ANSI  whiptail --backtitle "PARU NOT INSTALLED NOW" --title "Paru not install now" --infobox "Will have to install Paru later on" 10 78
    sleep 2
fi


## CHECK ANACONDA
read -p "Want to install anaconda?" yesno
if [ "$yesno" =~ 'y' ]; then
	[[ -f /opt/anaconda/bin/anaconda-navigator ]] || paru -S anaconda
fi

## REPLACE GNOME_TERMINAL WITH TRANSPARENCY VERSION (and mate-terminal)
paru -S gnome-terminal-transparency mate-terminal 

## INSTALL CHROME and ORANCHELO ICONS AND BREEZE CURSOR AND PAMAC
paru -S google-chrome oranchelo-icon-theme-git xcursor-breeze pamac-aur





