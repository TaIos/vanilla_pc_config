#!/bin/bash

## This script is for automating repetetive tasks 
## after installing new Linux system


#-------------------------------------------------------------------------------
# 1) Set gnome-terminal to open mazimized

sudo sed -i 's/^Exec=gnome-terminal$/Exec=gnome-terminal --window --maximize/' /usr/share/applications/org.gnome.Terminal.desktop

#-------------------------------------------------------------------------------
# 2) Install necessary applications
APPS="vim git xclip"
PACMAN="dnf"
PACMAN_FLAGS="install -y"

$PACMAN $PACMAN_FLAGS $APPS

#-------------------------------------------------------------------------------
# 3) Fetch git reposiroties
GIT_PASSWORD=1d0b23cb1666aa615728510ea2ff3005
TMP_REPO='/tmp/git_repos'

mkdir "${TMP_REPO}"
cd "${TMP_REPO}"
git clone https://kaldomain:"${GIT_PASSWORD}"@bitbucket.org/kaldomain/vimrc.git 
#rm -rf "${TMP_REPO}"

#-------------------------------------------------------------------------------
