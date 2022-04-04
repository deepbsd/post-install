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
echo "Did the following directories get made?  ${PERS_DIRECTORIES[@]}"; read empty

# Pick a host to get stuff from on the local network
echo "Download home directory files from what host on network?"; read whathost

# get ssh keys...
[ -d $HOME/.ssh ] || scp -o StrictHostKeyChecking=no -r dsj@"$whathost".lan:.ssh .

# check progress of getting ssh keys
echo "Did we get keys from $whathost ?"; read empty

# clone the latest dotfiles
echo "Ready to clone dotfiles?" ; read dotfiles
git clone $MY_DOTFILES

( $? && echo "Dotfiles clone successful." ) || echo "Problem with dotfiles clone..."

#scp -o StrictHostKeyChecking=no -r dsj@"$whathost".lan:{adm,dotfiles,.vim,public_html,sounds,.gkrellm2,wallpaper,wallpaper1,bin,.ssh,.gnupg,Music} .
#scp -Br dsj@"$whathost".lan:{adm,.vim,public_html,sounds,.gkrellm2,wallpaper,wallpaper1,bin,.gnupg,Music} .

eval $(ssh-agent) 
ssh-add $HOME/.ssh/id_rsa
$? && echo "Starting ssh-agent for ssh recursive copying..."

echo "Starting to recursively copy following directories:  ${MY_DIRS[@]}"
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
echo "Install powerline if not already installed."
$(which powerline >/dev/null) || sudo pacman -S powerline powerline-fonts

## CHECK FOR OLD FAITHFULS
echo "Install gkrellm if not already installed."
$(which gkrellm) || sudo pacman -S gkrellm
echo "Install anaconda if not already installed."
[[ -f /opt/anaconda/bin/anaconda-navigator ]] || paru -S anaconda

## INSTALL DEV STUFF 
echo "Installing Dev Stuff:  ${DEV_STUFF[@]}"
for f in ${DEV_STUFF[@]}; do
    sudo pacman -S $f
done

## DOTFILES
echo "Link dotfiles from cloned dotfiles repo..."
cp ~/.bashrc ~/.bashrc.orig
cp ~/.bash_profile ~/.bash_profile.orig
ln -sf ~/dotfiles/.bashrc .
ln -sf ~/dotfiles/.bash_profile .
ln -sf ~/dotfiles/.vimrc .

# NVM
echo "Create NVM clone..."
mkdir $HOME/.nvm
[[ -x $(which git &>/dev/null) ]] && cd && git clone https://github.com/nvm-sh/nvm.git .nvm/.
[[ -d $HOME/.nvm ]] && cd ~/.nvm && source ./nvm.sh && cd

## INSTALL PARU  
echo "Installing paru: "
[ -d $HOME/build ] || mkdir $HOME/build
cd ~/build
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
($? && echo "Paru successfully built.") || echo "Problem with building Paru!!!"
cd  # return to $HOME


## REPLACE GNOME_TERMINAL WITH TRANSPARENCY VERSION (and mate-terminal)
paru -S gnome-terminal-transparency mate-terminal 

## INSTALL CHROME and ORANCHELO ICONS AND BREEZE CURSOR
paru -S google-chrome oranchelo-icon-theme-git xcursor-breeze





