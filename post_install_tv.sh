#!/usr/bin/env bash

# Run this script after system and desktop are already installed

### VARIABLES ####
PERS_DIRECTORIES=( tmp build repos )
MY_DIRS=( .ssh adm .vim public_html sounds .gkrellm2 wallpaper wallpaper1 bin .gnupg Music )
MY_DOTFILES="https://github.com/deepbsd/dotfiles.git"
BASICS=( libdvdread libdvdcss libdvdnav gkrellm mlocate fzf )
DEV_STUFF=( nodejs ruby npm npm-check-updates gvim )

systemctl status systemd-homed
echo "Be sure to start and enable systemd-homed (as root) or else sudo may not work properly"
echo "Also, reinstall pambase if necessary `pacman -S pambase`"
echo "Type any to continue..." ; read empty

## PERSONAL DIRECTORIES AND RESOURCES
echo "Making personal subdirectories..."
mkdir "${PERS_DIRECTORIES[@]}"

# Pick a host to get stuff from on the local network
echo "Download home directory files from what host on network?"; read whathost

# get ssh keys...
[ -d $HOME/.ssh ] || scp -o StrictHostKeyChecking=no -r dsj@"$whathost".lan:.ssh .

# clone the latest dotfiles
git clone $MY_DOTFILES

#scp -o StrictHostKeyChecking=no -r dsj@"$whathost".lan:{adm,dotfiles,.vim,public_html,sounds,.gkrellm2,wallpaper,wallpaper1,bin,.ssh,.gnupg,Music} .
#scp -Br dsj@"$whathost".lan:{adm,.vim,public_html,sounds,.gkrellm2,wallpaper,wallpaper1,bin,.gnupg,Music} .
for dir in "${MY_DIRS[@]}" ; do
    echo "recursively copying $dir ..."
    scp -o StrictHostKeyChecking=no -r dsj@"$whathost".lan:$dir .
done

# SSH-AGENT SERVICE
echo "Start the ssh-agent service..."
eval $(ssh-agent)
ls ~/.ssh/* ; echo "Add which key? "; read key_name
ssh-add ~/.ssh/"$key_name"

## INSTALL DVD SUPPORT, GKRELLM, MLOCATE
sudo pacman -S ${BASICS[@]}
echo "updating locate database..."
sudo updatedb

## INSTALL POWERLINE
$(which powerline >/dev/null) || sudo pacman -S powerline powerline-fonts

## CHECK FOR OLD FAITHFULS
$(which gkrellm) || sudo pacman -S gkrellm
[[ -f /opt/anaconda/bin/anaconda-navigator ]] || paru -S anaconda

## INSTALL DEV STUFF 
for f in ${DEV_STUFF[@]}; do
    sudo pacman -S $f
done

## DOTFILES
cp ~/.bashrc ~/.bashrc.orig
cp ~/.bash_profile ~/.bash_profile.orig
ln -sf ~/dotfiles/.bashrc .
ln -sf ~/dotfiles/.bash_profile .
ln -sf ~/dotfiles/.vimrc .

# NVM
mkdir $HOME/.nvm
[[ -x $(which git &>/dev/null) ]] && cd && git clone https://github.com/nvm-sh/nvm.git .nvm/.
[[ -d $HOME/.nvm ]] && cd ~/.nvm && source ./nvm.sh && cd

## INSTALL PARU  
echo "Installing paru: "
cd ~/build
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd


## REPLACE GNOME_TERMINAL WITH TRANSPARENCY VERSION (and mate-terminal)
paru -S gnome-terminal-transparency mate-terminal 

## INSTALL CHROME and ORANCHELO ICONS AND BREEZE CURSOR
paru -S google-chrome oranchelo-icon-theme-git xcursor-breeze





