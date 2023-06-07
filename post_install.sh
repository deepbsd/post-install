#!/usr/bin/env bash

# Run this script on Arch systems after desktop are already installed

##########################
### VARIABLES, ARRAYS ####
##########################
LOGFILE=/tmp/logfile
SSH_KEY=$HOME/.ssh/id_rsa
# adjust as necessary
MY_DOTFILES="https://github.com/deepbsd/dotfiles.git"
# remove .vim directory.  That will be linked from dotfiles dir
FOLDERS=( adm sounds .gkrellm2 wallpaper wallpaper1 .ssh .gnupg .gnupg Music )
EMPTY_FOLDERS=( repos tmp build Downloads )
NORMAL_PKGS=( gkrellm libdvdread libdvdcss libdvdnav mlocate fzf powerline powerline-fonts powerline-vim )
DEV_PKGS=( ruby nodejs npm npm-check-updates bash-bats bash-bats-support bash-bats-asserts )
CLONED_REPOS=( "https://github.com/deepbsd/dotfiles.git" "https://aur.archlinux.org/paru.git" "https://github.com/nvm-sh/nvm.git" )
AUR_PKGS=( anaconda gnome-terminal-transparency mate-terminal google-chrome oranchelo-icon-theme-git xcursor-breeze pamac-aur )

# Need this array to keep track of what's completed
completed_tasks=( "X" )


#####################
####  FUNCTIONS
#####################

# CREATE LOGFILE
create_logfile(){
    touch $LOGFILE
    echo "STARTING post_install.sh $date " &>$LOGFILE
}


# check if a program is already installed
check_install(){
    app=$1
    if paru -Qi $app &>>$LOGFILE ; then
        whiptail --title "$app Installation Status" --backtitle "$app IS INSTALLED"  --msgbox "  
        "$app is installed already."

        Hit OK to Continue" 40 78
        return 0
    else
        return 1
    fi
}

# CHECK IF TASK IS COMPLETED
check_tasks(){

    # If task already exists in array return falsy
    # Function takes a task number as an argument
    # This function might not be needed anymore: STATUS TBD

    # just return an 'X' in the array position of the passed integer parameter
    completed_tasks[$1]="X"
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

    # Ask to change repo url
    if $( whiptail --backtitle "CHANGE DOTFILE REPO URL?" --title "Set New DOTFILE Repo?" --yesno "Your Dotfile URL is $MY_DOTFILES  Do you want to change it?" 9 78  3>&1 1>&2 2>&3 );
    then
        DOTFILE_URL=$( whiptail --backtitle "YOUR NEW DOTFILE URL" --title "Input your new dotfile repo:" --inputbox  \
        "Your new DOTFILE Repo URL:" 20 78 3>&1 1>&2 2>&3 )
        MY_DOTFILES="$DOTFILE_URL"
    else
        TERM=ansi whiptail --title "Keeping Dotfile URL of $MY_DOTFILES" --infobox "Your dotfile url is still $MY_DOTFILES" 8 78
        sleep 2
    fi


    # Proceed to actually make empty folders and clone dotfiles
    if $(whiptail --title "Personal Directories and dotfiles..." --backtitle \
        "Installing and Cloning Personal Customized Directories" --yesno \
        "Do you want to create your personal files and folders?"  10 78 3>&1 1>&2 2>&3); then
        cd $HOME 
        mkdir "${EMPTY_FOLDERS[@]}"  &>>$LOGFILE
        git clone "$MY_DOTFILES" &>>$LOGFILE

    else
        TERM=ansi whiptail --backtitle "FILES NOT CREATED" --title "Moving on..." --infobox "Not creating personal files and directories..." 8 78
        sleep 2
    fi
}


# CREATE AND COPY HOME DIRS
create_homedirs(){
    ## Create the empty directories, copy recursively the non-empty directories

    echo "=== Creating and Copying Home Directories ===" &>>$LOGFILE

    # THESE DIRECTORIES ARE STANDARD FOR MY HOME DIRECTORIES ON ALL MY SYSTEMS
    if $(whiptail --backtitle "COPYING DIRECTORIES" --title "Copying Directories to Home Folder"\
        --yesno "Copy directories to home $HOME?"  10 78 3>&1 1>&2 2>&3); 
    then

        # CHOOSE HOST ON NETWORK TO DOWNLOAD FILES AND DIRS FROM
        host=$(whiptail --backtitle "CHOOSE HOSTNAME" --title "Enter hostname to download from:" \
        --inputbox "What host to download directories from?"  10 40 3>&1 1>&2 2>&3)

        ### GENERATE THE DIRECTORIES FROM THE LIST OF FOLDERS
        myfolders=$(for f in "${FOLDERS[*]}"; do printf "%s  \"<---\" ON\n" $f; done)


        # CHOOSE FOLDERS TO COPY
        folders=$(whiptail --title "Choose directories to copy" --backtitle "CHOOSE DIRECTORIES" --checklist \
        "Choose Folder Options:" 20 78 13 \
        $(echo -e "$myfolders") 3>&1 1>&2 2>&3 )

        # CREATE AND COPY HOMEDIRS (Replace each space with a comma between dir names)
        homedirs=( $( echo "${folders}" | sed -e 's/\"//g' )  )
        for f in "${homedirs[@]}"; do
            echo "copying dsj@$host.lan/$f ..."
            scp -o StrictHostKeyChecking=no -r dsj@"$host".lan:"$f" .  #&>>$LOGFILE
        done
        ##scp -Br dsj@"$whathost".lan:{adm,dotfiles,.vim,public_html,sounds,.gkrellm2,wallpaper,wallpaper1,bin,.ssh,.gnupg} .

        whiptail --backtitle "DIRECTORIES COPIED" --title "Folders copied" --infobox $LOGFILE  30 78
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
        ln -sf ~/dotfiles/.vim .    &>>$LOGFILE
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

    sleep 2      # won't see the infobox without a sleep statement
    #[[ -f ~/.ssh/id_rsa ]] && eval $(ssh-agent) 2&>/dev/null
    [[ -f "$SSH_KEY" ]] && eval $(ssh-agent) &>>$LOGFILE 

    password=$(whiptail --backtitle "SUDO PASSWORD CHECKER" --title "Check sudo with auto password" --passwordbox "Please enter your SUDO password" 8 78 3>&1 1>&2 2>&3 )
   
    [[ -f /usr/lib/ssh/x11-ssh-ask-pass ]] || echo "$password" | sudo -S pacman --noconfirm -S x11-ssh-askpass &>>$LOGFILE
    
    whiptail --backtitle "DID WE INSTALL ssh-ask-pass?" --title "Did we install ssh-ask-pass?" --textbox $LOGFILE  40 78

    ## NOTE: ADD CHECK FOR SSH_ASKPASS PROGRAM BEFORE THIS
    export SSH_ASKPASS=/usr/lib/ssh/x11-ssh-askpass
    export SSH_ASKPASS_REQUIRE="prefer"
    #ssh-add ~/.ssh/id_rsa  &>>$LOGFILE
    eval $(ssh-agent) && ssh-add "$SSH_KEY"   &>>$LOGFILE

    # determine whether the key got added properly or not and inform the user
    if [[ $? == 0 ]]; then
        echo "===SUCCESS!!  Added ssh identify to ssh-agent!!===">>$LOGFILE
        TERM=ansi whiptail --title "Success adding your ssh-key to ssh-agent" --msgbox "Adding your ssh secret key to running ssh-agent..." 10 78
    else
        echo "===FAILURE!!  No ssh identity added to ssh-agent!!===">>$LOGFILE
        TERM=ansi whiptail --title "Failure adding your ssh-key to ssh-agent" --msgbox "Failure adding your ssh secret key to running ssh-agent..." 10 78

    fi

    whiptail --backtitle "SSH-ADD STATUS" --title "Status for ssh-add command: " --textbox $LOGFILE  10 78
}



# INSTALL MYSTUFF
install_mystuff(){
    echo "=== Installing gkrellm, libdvdread, libdvdcss, libdvdnav, mlocate, fzf, powerline, powerline-fonts ===" &>>$LOGFILE
    if $(whiptail --backtitle "INSTALL MYSTUFF" --title "Install Mystuff?"  \
        --yesno "Install Gkrellm, DVD support, Mlocate, and fzf?" 10 78 3>&1 1>&2 2>&3)
    then
    
        password=$(whiptail --backtitle "SUDO PASSWORD CHECKER" --title "Check sudo with auto password" --passwordbox "Please enter your SUDO password" 8 78 3>&1 1>&2 2>&3 )
        
        ## NOTE: ADD CHECK FOR SSH_ASKPASS PROGRAM BEFORE THIS
        export SSH_ASKPASS=/usr/lib/ssh/x11-ssh-askpass
        export SSH_ASKPASS_REQUIRE="prefer"
        ssh-add ~/.ssh/id_rsa  &>>$LOGFILE

        ## SYNC PACMAN DBs
        echo "$password" | sudo --user=root --stdin pacman -Syy  &>>$LOGFILE

        ## INSTALL GKRELLM, DVD SUPPORT, MLOCATE FUZZY FILEFINDER
        term=ANSI  whiptail --backtitle "INSTALLING MYSTUFF " --title "Installing Mystuff " --infobox "Installing ${NORMAL_PKGS[@]} " 10 78
        echo "$password" | sudo --user=root --stdin pacman --noconfirm -S "${NORMAL_PKGS[@]}" &>>$LOGFILE

        echo "$password" | sudo --user=root --stdin updatedb  

        whiptail --backtitle "MYSTUFF INSTALLED" --title "MyStuff Installation Status" --textbox "$LOGFILE" 30 78
    else
        term=ANSI  whiptail --backtitle "MYSTUFF NOT INSTALLED NOW" --title "Mystuff not install now" --infobox "Will have to install Mystuff later on" 10 78
        sleep 2
        whiptail --backtitle "MYSTUFF NOT INSTALLED" --title "MyStuff Installation Status" --textbox "$LOGFILE" 30 78

    fi
}


## INSTALL POWERLINE AND DEV STUFF 
install_devstuff(){
    echo "=== Installing ruby, nodejs, npm, npm-check-updates, gvim, mlocate ===" &>>$LOGFILE
    if $(whiptail --backtitle "INSTALL DEVSTUFF" --title "Install Devstuff?"  --yesno "Install Ruby, node, npm, gvim, npm-check-updates?" 10 78 3>&1 1>&2 2>&3)
    then
        password=$(whiptail --backtitle "SUDO PASSWORD CHECKER" --title "Check sudo with auto password" --passwordbox "Please enter your SUDO password" 8 78 3>&1 1>&2 2>&3 )

        echo "$password" | sudo -S pacman --noconfirm -S "${DEV_PKGS[*]}" &>>$LOGFILE

        echo "$password" | sudo -S pacman -S gvim &>>$LOGFILE

        whiptail --backtitle "DEVSTUFF INSTALLED" --title "DevStuff Installation Status" --textbox "$LOGFILE" 30 78
    else
        term=ANSI  whiptail --backtitle "DEVSTUFF NOT INSTALLED NOW" --title "Devstuff not installed now" --infobox "Will have to install Devstuff later on" 10 78
        sleep 2
    fi

    whiptail --backtitle "MYSTUFF INSTALLED" --title "MyStuff Installation Status" --textbox "$LOGFILE" 30 78
}


# NVM
install_nvm(){
    ## YESNO TO INSTALL NVM
    echo "=== Install NVM shell script ===" &>>$LOGFILE
    if $(whiptail --backtitle "INSTALL NVM" --title "Install NVM?"  --yesno "Install NVM?" 10 78 3>&1 1>&2 2>&3)
    then
        mkdir $HOME/.nvm
        cd && git clone https://github.com/nvm-sh/nvm.git $HOME/.nvm/. 
        cd $HOME/.nvm && source nvm.sh && cd  
        whiptail --backtitle "NVM INSTALLED" --title "NVM Installation Status" --infobox "$LOGFILE" 30 78
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
        if ! which paru >>$LOGFILE  ; then
            cd ~/build
            git clone https://aur.archlinux.org/paru.git 
            cd paru
            makepkg -si   
            cd
        fi
        whiptail --backtitle "PARU INSTALLED" --title "PARU Installation Status" --infobox "$LOGFILE" 30 78
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
        [[ -f /opt/anaconda/bin/anaconda-navigator ]] || paru -S anaconda  &>>$LOGFILE
        whiptail --backtitle "ANACONDA INSTALLED" --title "Anaconda Installation Status" --infobox "$LOGFILE" 30 78
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
        paru -S gnome-terminal-transparency mate-terminal &>>$LOGFILE
        paru -S google-chrome oranchelo-icon-theme-git xcursor-breeze pamac-aur  &>>$LOGFILE
        whiptail --backtitle "AUR GOODIES INSTALLED" --title "AUR Goodies Installation Status" --infobox "$LOGFILE" 30 78
    else
        term=ANSI  whiptail --backtitle "NOT INSTALLED AUR GOODIES NOW" --title "Not installing AUR goodies now" --infobox "Will have to install AUR Goodies later on" 10 78
        sleep 2
    fi
}

###################################
########      MAIN     ############
###################################

main(){
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

startmenu(){
    create_logfile
    homed_message
    pambase_reminder

    while true ; do
        menupick=$(
        whiptail --backtitle "Post Install Installer" --title "Main Menu" --menu "Your choice?" 30 70 20 \
            "D"   "[$(echo ${completed_tasks[1]}]    Clone your dotfiles )"  \
            "H"   "[$(echo ${completed_tasks[2]}]    Creat your home directories )"  \
            "L"   "[$(echo ${completed_tasks[3]}]    Link your dotfiles )"  \
            "S"   "[$(echo ${completed_tasks[4]}]    Start SSH Agent service )"  \
            "M"   "[$(echo ${completed_tasks[5]}]    Install MyStuff )"        \
            "V"   "[$(echo ${completed_tasks[6]}]    Install Programmer Dev Stuff )"    \
            "N"   "[$(echo ${completed_tasks[7]}]    Install NVM )"           \
            "P"   "[$(echo ${completed_tasks[8]}]    Install Paru )"          \
            "A"   "[$(echo ${completed_tasks[9]}]    Install Anaconda  )" \
            "R"   "[$(echo ${completed_tasks[10]}]   Install AUR Goodies  ) "   \
            "Q"   "[$(echo ${completed_tasks[17]}]   Quit Script) "  3>&1 1>&2 2>&3
        )

        case $menupick in

            "D")  cloning_dotfiles; check_tasks 1 ;;

            "H")  create_homedirs;  check_tasks 2 ;;

            "L")  link_dotfiles;  check_tasks 3 ;;

            "S")  ssh_agent_service; check_tasks 4 ;;
            
            "M")  install_mystuff; check_tasks 5 ;;

            "V")  install_devstuff; check_tasks 6 ;;

            "N")  install_nvm; check_tasks 7 ;;

            "P")  install_paru; check_tasks 8 ;;
            
            "A")  install_anaconda; check_tasks 9 ;;
            
            "R")  install_aur_goodies; check_tasks 10 ;;
            
            "Q")  echo "Have a nice day!" ; exit 0 ;;

        esac
    done
}


### START HERE
startmenu


