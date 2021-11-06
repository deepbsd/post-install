#!/usr/bin/env bash

# Run this script after system and desktop are already installed

homed_message=$(systemctl status systemd-homed)

whiptail --title "Homed Status" --backtitle "HOMED-STATUS"  --msgbox "${homed_message}  


Hit OK to Continue" 40 78

whiptail --title "Pambase Reminder" --backtitle "PAMBASE REMINDER"  --msgbox "Remember to enable systemd-homed as root or sudo may not work correctly.  

Also, reinstall pambase if necessary.  Hit OK to Continue."  10 78


## PERSONAL DIRECTORIES AND RESOURCES
TERM=ansi whiptail --title "Personal Directories and dotfiles..." --backtitle "Installing and Cloning Personal Customized Directories"  --infobox "Creating Personal Folders in Home Directory..."  10 78

## CHANGE FROM 'ECHO'
echo mkdir tmp repos build 
echo git clone https://github.com/deepbsd/dotfiles.git

sleep 2

host=$(whiptail --backtitle "CHOOSE HOSTNAME" --title "Enter hostname to download from:" \
--inputbox "What host to download directories from?"  10 40 3>&1 1>&2 2>&3)


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

homedirs=$( echo "${folders}" | sed -e 's/\"//g' | sed -e 's/ /,/g' )

##  REMOVE ECHO!!
echo scp -o StrictHostKeyChecking=no -r dsj@"$host".lan:{"$homedirs"} .

##scp -Br dsj@"$whathost".lan:{adm,dotfiles,.vim,public_html,sounds,.gkrellm2,wallpaper,wallpaper1,bin,.ssh,.gnupg,Music} .
#

TERM=ansi whiptail --backtitle "LINKING DOTFILES..." --title "Backing Up and Linking Dotfiles" --infobox \
"Copying .bashrc.orig .bash_profile.orig .vimrc.orig and linking new dotfiles to cloned masters"  10 78

## DOTFILES
#cp ~/.bashrc ~/.bashrc.orig
#cp ~/.bash_profile ~/.bash_profile.orig
#ln -sf ~/dotfiles/.bashrc .
#ln -sf ~/dotfiles/.bash_profile .
#ln -sf ~/dotfiles/.vimrc .

sleep 3
exit

# SSH-AGENT SERVICE
echo "Start the ssh-agent service..."
eval $(ssh-agent)
ls ~/.ssh/* ; echo "Add which key? "; read key_name
ssh-add ~/.ssh/"$key_name"

## SYNC PACMAN DBs
sudo pacman -Syy

## INSTALL GKRELLM, DVD SUPPORT, MLOCATE
$(which gkrellm &>/dev/null) || sudo pacman -S gkrellm
sudo pacman -S libdvdread libdvdcss libdvdnav mlocate fzf
echo "updating locate database..."
sudo updatedb

## INSTALL POWERLINE
$(which powerline >/dev/null) || sudo pacman -S powerline powerline-fonts

## INSTALL POWERLINE AND DEV STUFF 
sudo pacman -S  ruby nodejs npm npm-check-updates gvim mlocate 

# NVM
mkdir $HOME/.nvm
[[ -x $(which git &>/dev/null) ]] && cd && git clone https://github.com/nvm-sh/nvm.git .nvm/.
[[ -d ~/.nvm ]] && cd ~/.nvm && source nvm.sh && cd

## INSTALL YAY  ## Do this last because of intermittant errors with yay-git
if [ ! $(( which paru &>/dev/null )) ]; then
    echo "Installing paru: "
    cd ~/build
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si
    cd
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





