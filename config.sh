#!/bin/bash

## This script is for automating repetetive tasks 
## after installing new Linux system
#
#
## Particular sections can be invoked passing argument
## arguments: all, terminal, apps, git_config, git_fetch

case "$1" in

	#-------------------------------------------------------------------------------
	# 1) Set gnome-terminal to open mazimized
	terminal|all)

	sudo sed -i 's/^Exec=gnome-terminal$/Exec=gnome-terminal --window --maximize/' /usr/share/applications/org.gnome.Terminal.desktop
	;;&
	
	#-------------------------------------------------------------------------------
	# 2) Install necessary applications
	apps|all)

	APPS="vim git xclip"
	PACMAN="dnf"
	PACMAN_FLAGS="install -y"

	sudo $PACMAN $PACMAN_FLAGS $APPS
	;;&

	#-------------------------------------------------------------------------------
	# 3) Setup GIT
	git_config|all)

	git config --global user.name "Martin Safranek"
	git config --global user.email "martinsafranek1997@seznam.cz"
	git config --global core.editor vim

	git config --global alias.co checkout
	git config --global alias.br branch
	git config --global alias.ci commit
	git config --global alias.st status
	git config --global alias.ll 'log --oneline --graph --all --decorate'
	;;&

	#-------------------------------------------------------------------------------
	# 4) Fetch GIT reposiroties
	git_fetch|all)

	GIT_PASSWORD=""
	TMP_REPO='/tmp/git_repos'

	read -sp 'GIT password: ' GIT_PASSWORD

	mkdir "${TMP_REPO}"
	cd "${TMP_REPO}"
	git clone https://kaldomain:"${GIT_PASSWORD}"@bitbucket.org/kaldomain/vimrc.git 
	git clone https://kaldomain:"${GIT_PASSWORD}"@bitbucket.org/kaldomain/bashrc.git
	git clone https://kaldomain:"${GIT_PASSWORD}"@bitbucket.org/kaldomain/develop.git
	git clone https://kaldomain:"${GIT_PASSWORD}"@bitbucket.org/kaldomain/dokumenty.git


	rm -rf "${TMP_REPO}"
	;;&

	#-------------------------------------------------------------------------------
esac
