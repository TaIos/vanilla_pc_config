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
	PACMAN="pacman"
	PACMAN_FLAGS="-Sy"

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
	HOME_DIR='/home/slarty'

	read -sp 'GIT password: ' GIT_PASSWORD
	
	mkdir "${TMP_REPO}"
	cd "${TMP_REPO}"

	CLONED_DIRS="vimrc bashrc develop dokumenty"
	git clone https://kaldomain:"${GIT_PASSWORD}"@bitbucket.org/kaldomain/vimrc.git 
	VIMRC=vimrc
	#git clone https://kaldomain:"${GIT_PASSWORD}"@bitbucket.org/kaldomain/bashrc.git
	#BASHRC=bashrc
	#git clone https://kaldomain:"${GIT_PASSWORD}"@bitbucket.org/kaldomain/develop.git
	#DEVELOP=develop
	#git clone https://kaldomain:"${GIT_PASSWORD}"@bitbucket.org/kaldomain/dokumenty.git
	#DOKUMENTY=dokumenty


    setopt shwordsplit # splitting string as words

	for dir in $CLONED_DIRS
	do
		if [ ! -d "${HOME_DIR}/${dir}" ]
		then
			#mkdir "${HOME_DIR}/${dir}"
			echo "Directory $dir does not exits"
		else
			echo "Directory $dir exists"
		fi
	done

	rm -rf "${TMP_REPO}"
	exit 0


	# VIMRC
	if  [ -z "$(ls -A "${HOME_DIR}/${VIMRC}")" ]
	then
			echo "First branch"
			cp -r "${TMP_REPO}/${VIMRC}/"* "${HOME_DIR}/${VIMRC}" 
	else
		echo "Second branch"
		mkdir "${HOME_DIR}/${VIMRC}_tmp"
		cp -r "${TMP_REPO}/${VIMRC}/"* "${HOME_DIR}/${VIMRC}_tmp"
	fi

	# BASHRC
	#if  [ "$(ls -A "${HOME_DIR}/bashrc_dir")" ]
	#then
#
	#fi
#
	## DEVELOP
	#if  [ "$(ls -A "${HOME_DIR}/develop_dir")" ]
#
	## DOKUMENTY
	#if  [ "$(ls -A "${HOME_DIR}/Dokumenty")" ]


	rm -rf "${TMP_REPO}"
	;;&

	#-------------------------------------------------------------------------------
esac
