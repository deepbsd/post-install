#!/usr/bin/env bash

# Run this script on Arch systems after desktop are already installed
# This script uses whiptail

##########################
### VARIABLES, ARRAYS ####
##########################
user=dsj
LOGFILE=/tmp/logfile
SSH_KEY=$HOME/.ssh/id_rsa
declare -A CLONED_REPOS=( [dotfiles]="https://github.com/deepbsd/dotfiles.git" [paru]="https://aur.archlinux.org/paru.git" [nvm]="https://github.com/nvm-sh/nvm.git" )
MY_DOTFILES="${CLONED_REPOS[dotfiles]}"
PARU_REPO="${CLONED_REPOS[paru]}"
NVM_REPO="${CLONED_REPOS[nvm]}"
FOLDERS=( adm sounds bin .gkrellm2 wallpaper wallpaper1 public_html .ssh .gnupg Music )
EMPTY_FOLDERS=( repos tmp build Downloads Documents dwhelper movies )
NORMAL_PKGS=( gvim htop gkrellm scrot libdvdread libdvdcss libdvdnav mlocate fzf powerline powerline-fonts powerline-vim )
DEV_PKGS=( ruby nodejs npm npm-check-updates bash-bats bash-bats-support bash-bats-asserts )
AUR_PKGS=( gparted aisleriot gnome-terminal-transparency mate-terminal google-chrome oranchelo-icon-theme-git xcursor-breeze pamac-aur )
OPTIONAL=( libreoffice-still )

# Need this array to keep track of what's completed
completed_tasks=( "X" )


#####################
####  FUNCTIONS
#####################

# CREATE LOGFILE
create_logfile(){
    touch $LOGFILE
    date=$(date)
    echo "===== STARTING post_install.sh ==== $date ====" &>$LOGFILE
}

system_update(){
    sudo pacman -Syyu --noconfirm  &>>$LOGFILE
}

# check if a program is already installed
check_install(){
    app=$1
    if paru -Qi $app &>>$LOGFILE ; then
        echo "=== checking installation status for $app ===" &>>$LOGFILE
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

# NOTE:  Showing a progress gauge in whiptail is a pain.  I do it by 
# passing the name of the process to measure (a function name) to a
# calling function.  The calling function calls the function and sends
# it to the background, and then immediately captures its PID.  
# We check for that PID and keep showing the progress meter if its still
# in the PID table.  If it drops out of the PID table, then we immediately
# show 98 99 100 pct progress with a 3 second wait between each.
# If the process is taking a very long time, we show 97pct 98pct 97pct 
# 98pct until the PID drops out of the PID table.  This way the user
# never suspects the install has frozen, just that he's going spastic.


# FOR SHOWING PROGRESS GAUGE FOR WHIPTAIL (this does the counting)
showprogress(){
    # start count, end count, shortest sleep, longest sleep
    start=$1; end=$2; shortest=$3; longest=$4

    for n in $(seq $start $end); do
        echo $n
        pause=$(shuf -i ${shortest:=1}-${longest:=3} -n 1)  # random wait between 1 and 3 seconds
        sleep $pause
    done
}

# CALL FOR SHOWING PROGRESS GAUGE (this calls the function)
specialprogressgauge(){
    process_to_measure=$1   # This is the function we're going to measure progress for
    message=$2              # Message on Whiptail progress window
    backmessage=$3          # Message on Background Window
    eval $process_to_measure &      # Start the process in the background
    thepid=$!               # Immediately capture the PID for this process
    echo "=== Watching PID $thepid for progress ===" &>>$LOGFILE
    num=10                  # Shortest progress bar could be 10 sec to 30 sec
    while true; do
        showprogress 1 $num 1 3 
        sleep 2             # Max of 47 sec before we check for completion
        while $(ps aux | grep -v 'grep' | grep "$thepid" &>/dev/null); do
            if [[ $num -gt 97 ]] ; then num=$(( num-1 )); fi
            showprogress $num $((num+1)) 
            num=$(( num+1 ))
        done
        showprogress 99 100 3 3  # If we have completion, we add 6 sec. Max of 53 sec.
        echo "=== No longer watching PID: $thepid ===" &>>$LOGFILE
        break
    done  | whiptail --backtitle "$backmessage" --title "Progress Gauge" --gauge "$message" 9 70 0
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
}


# COPY DIRECTORIES FROM DESIGNATED HOST
do_dir_copy(){
    #  Have to figure out how to do this...
    continue 
}

# CREATE AND COPY HOME DIRS
create_homedirs(){
    ## Create the empty directories, copy recursively the non-empty directories

    echo "=== Creating and Copying Home Directories ===" &>>$LOGFILE

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
        for dir in "${homedirs[@]}"; do
            echo "copying $user@$host.lan/$dir ..."
            scp -o StrictHostKeyChecking=no -r $user@"$host".lan:"$dir" .  &>>$LOGFILE
            #scp -r $user@"$host".lan:"$f" .  #&>>$LOGFILE
        done

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

    [[ -f "$SSH_KEY" ]] && eval $(ssh-agent) &>>$LOGFILE 

    password=$(whiptail --backtitle "SUDO PASSWORD CHECKER" --title "Check sudo with auto password" --passwordbox "Please enter your SUDO password" 8 78 3>&1 1>&2 2>&3 )
   
    [[ -f /usr/lib/ssh/x11-ssh-ask-pass ]] || echo "$password" | sudo -S pacman --noconfirm -S x11-ssh-askpass &>>$LOGFILE
    
    whiptail --backtitle "DID WE INSTALL ssh-ask-pass?" --title "Did we install ssh-ask-pass?" --textbox $LOGFILE  40 78

    ## NOTE: ADD CHECK FOR SSH_ASKPASS PROGRAM BEFORE THIS
    export SSH_ASKPASS=/usr/lib/ssh/x11-ssh-askpass
    export SSH_ASKPASS_REQUIRE="prefer"

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
        term=ANSI  whiptail --backtitle "INSTALLING MYSTUFF " --title "Installing Mystuff " --infobox "Installing Normal Packages " 10 78

        for pkg in "${NORMAL_PKGS[@]}"; do
            if $( ! check_install $pkg ); then
                echo "$password" | sudo --user=root --stdin pacman --noconfirm -S "$pkg" &>>$LOGFILE
            else
                TERM=ansi whiptail --title "$pkg is already installed" --msgbox "$pkg is already installed" 10 78

            fi
        done


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
    echo "=== Installing ruby, nodejs, npm, npm-check-updates, mlocate ===" &>>$LOGFILE
    if $(whiptail --backtitle "INSTALL DEVSTUFF" --title "Install Devstuff?"  --yesno "Install Ruby, node, npm, npm-check-updates?" 10 78 3>&1 1>&2 2>&3)
    then
        password=$(whiptail --backtitle "SUDO PASSWORD CHECKER" --title "Check sudo with auto password" --passwordbox "Please enter your SUDO password" 8 78 3>&1 1>&2 2>&3 )

        for f in "${DEV_PKGS[*]}" ; do

            if $( ! check_install $f ); then
                echo "$password" | sudo -S pacman --noconfirm "$f" 
            else
                TERM=ansi whiptail --title "$f is already installed" --msgbox "$f is already installed" 10 78
            fi

        done

        whiptail --backtitle "DEVSTUFF INSTALLED" --title "DevStuff Installation Status" --msgbox "SUCCESS!!!" 30 78
    else
        term=ANSI  whiptail --backtitle "DEVSTUFF NOT INSTALLED NOW" --title "Devstuff not installed now" --infobox "Will have to install Devstuff later on" 10 78
        sleep 2
    fi

    whiptail --backtitle "DEVSTUFF INSTALLED" --title "MyStuff Installation Status" --textbox "$LOGFILE" 30 78
}


# NVM
install_nvm(){
    ## YESNO TO INSTALL NVM
    echo "=== Install NVM shell script ===" &>>$LOGFILE
    if $(whiptail --backtitle "INSTALL NVM" --title "Install NVM?"  --yesno "Install NVM?" 10 78 3>&1 1>&2 2>&3)
    then
        mkdir $HOME/.nvm
        #cd && git clone https://github.com/nvm-sh/nvm.git $HOME/.nvm/. 
        cd && git clone $NVM_REPO $HOME/.nvm/.
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
        if  $(! which paru &>>$LOGFILE) ; then
            echo "==== Building Paru ====" &>>$LOGFILE
            [[ -d $HOME/build ]] || mkdir $HOME/build &>>$LOGFILE
            cd $HOME/build
            git clone "$PARU_REPO" &>>$LOGFILE
            cd paru
            makepkg -si  &>>$LOGFILE 
            cd
            TERM=ansi whiptail --title "Paru installed successfully!" --msgbox "Congrats! Paru Installed!" 10 78
        else
            TERM=ansi whiptail --title "Paru is already installed" --msgbox "Paru is already installed" 10 78
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
    echo "=== Installing ${AUR_PKGS[@]} ===" &>>$LOGFILE

    if $(whiptail --backtitle "INSTALL AUR GOODIES" --title "Install AUR Pkgs?"  --yesno "Install Aur Goodies?" 10 78 3>&1 1>&2 2>&3)
    then

        for app in ${AUR_PKGS[@]} ; do
            if $( ! check_install $app ); then
                paru -S $app
            else
                TERM=ansi whiptail --title "$app is already installed" --msgbox "$app is already installed" 10 78
            fi
        done

        whiptail --backtitle "AUR GOODIES INSTALLED" --title "AUR Goodies Installation Status" --infobox "$LOGFILE" 30 78
    else
        term=ANSI  whiptail --backtitle "NOT INSTALLED AUR GOODIES NOW" --title "Not installing AUR goodies now" --infobox "Will have to install AUR Goodies later on" 10 78
        sleep 2
    fi
}

# INSTALL OPTIONAL PKGS
install_optional(){
    echo "=== Install Optional: ${OPTIONAL[@]} ===" &>>$LOGFILE
    if $(whiptail --backtitle "INSTALL OPTIONAL PKGS" --title "Install Optional PKGS"  --yesno "Install Optional PKGS?" 10 78 3>&1 1>&2 2>&3)
    then
        for app in "${OPTIONAL[@]}"; do

            if $(! check_install $app) ; then
                paru -S $app 
            else
                TERM=ansi whiptail --title "$app is already installed" --msgbox "$app is already installed" 10 78
                #echo "$app is installed already..."
            fi
        done
        
        whiptail --backtitle "OPTIONAL PKGS INSTALLED" --title "Optional Pkgs Installation Status" --infobox "$LOGFILE" 30 78
    else
        term=ANSI  whiptail --backtitle "OPTIONAL PKGS NOT INSTALLED NOW" --title "Not installing optional pkgs now" --infobox "Will have to install optional pkgs later on" 10 78
        sleep 2
    fi
}

###################################
########      MAIN MENU    ########
###################################

main_menu(){
    create_logfile
    homed_message
    pambase_reminder

    while true ; do
        menupick=$(
        whiptail --backtitle "Post Install Installer" --title "Main Menu" --menu "Your choice?" 30 70 20 \
            "U"   "[$(echo ${completed_tasks[1]}]    Update System )"  \
            "H"   "[$(echo ${completed_tasks[2]}]    Creat and copy your home directories )"  \
            "D"   "[$(echo ${completed_tasks[3]}]    Clone your dotfiles )"  \
            "L"   "[$(echo ${completed_tasks[4]}]    Link your dotfiles )"  \
            "S"   "[$(echo ${completed_tasks[5]}]    Start SSH Agent service )"  \
            "P"   "[$(echo ${completed_tasks[6]}]    Install Paru )"          \
            "M"   "[$(echo ${completed_tasks[7]}]    Install MyStuff )"        \
            "V"   "[$(echo ${completed_tasks[8]}]    Install Programmer Dev Stuff )"    \
            "N"   "[$(echo ${completed_tasks[9]}]    Install NVM )"           \
            "A"   "[$(echo ${completed_tasks[10]}]    Install Anaconda  )" \
            "R"   "[$(echo ${completed_tasks[11]}]   Install AUR Goodies  ) "   \
            "O"   "[$(echo ${completed_tasks[12]}]   Install Optional  ) "   \
            "Q"   "[$(echo ${completed_tasks[13]}]   Quit Script) "  3>&1 1>&2 2>&3
        )

        case $menupick in

            "U") specialprogressgauge system_update "Updating System" "UPDATING SYSTEM"; check_tasks 1 ;;

            "H")  create_homedirs;  check_tasks 2 ;;

            "D")  cloning_dotfiles; check_tasks 3 ;;

            "L")  link_dotfiles;  check_tasks 4 ;;

            "S")  ssh_agent_service; check_tasks 5 ;;
 
            "P")  install_paru; check_tasks 6 ;;
            
            "M")  install_mystuff; check_tasks 7 ;;

            "V")  install_devstuff; check_tasks 8 ;;

            "N")  install_nvm; check_tasks 9 ;;
           
            "A")  install_anaconda; check_tasks 10 ;;
            
            "R")  install_aur_goodies; check_tasks 11 ;;
            
            "O")  install_optional; check_tasks 12 ;;
            
            "Q")  echo "Have a nice day!" ; exit 0 ;;

        esac
    done
}


### START HERE
main_menu


