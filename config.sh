#!/bin/bash

## This script is for automating repetetive tasks 
## after installing new Linux system
#
#
## Particular sections can be invoked passing argument/s
## arguments: all, terminal, apps, git_config, git_fetch

for arg in "$@"
do
	case "$arg" in

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
		# 4) Fetch GIT reposiroties & cpy them to home
		git_fetch|all)

		GIT_PASSWORD="test"
		CLONED_DIRS="vimrc bashrc develop dokumenty"
		CLONED_DIRS="vimrc bashrc develop"
		TMP_REPO='/tmp/git_repos_tmp'
		HOME_DIR='/home/slarty'

		# create TMP_REPO if it doesn't exist
		if [ ! -d "${TMP_REPO}" ]
		then
			mkdir "${TMP_REPO}"
		fi

		cd "${TMP_REPO}"


		if [ -z "$GIT_PASSWORD" ]
		then
			read -sp 'GIT password: ' GIT_PASSWORD
		fi

		# Enable if shell is not interpreting string as words 
		# (not splitting the string as individual words, interpreting as one string)
		#setopt shwordsplit

		# 1) Clone git repos to /tmp/TMP_REPO
		# 2) Create dirs specified in CLONED_DIRS in HOME_DIR, if they do not exist
		# 3) Copy cloned git repos from /tmp/TMP_REPO to created dirs in HOME_DIR
		# 4) Setup vimrc/bashrc
		for dir in $CLONED_DIRS
		do

			echo "$dir"
			continue
			# 1) clone git repos
			git clone https://kaldomain:"${GIT_PASSWORD}"@bitbucket.org/kaldomain/"${dir}".git 

			# 2) create dirs
			if [ ! -d "${HOME_DIR}/${dir}" ]
			then
				mkdir "${HOME_DIR}/${dir}"
			fi

			# 3) copy to dirs
			# if the directory is empty, copy to it
			if [ -z "$(ls -A  "${HOME_DIR}/${dir}")" ]
			then
					cp -r "${TMP_DIR}/$dir}" "${HOME_DIR}/${dir}"
			# directory is not empty, create HOME_DIR/dir tmp dir and copy to it
			else
				mkdir "${HOME_DIR}/${dir}_tmp"
				cp -r "${TMP_DIR}/$dir}" "${HOME_DIR}/${dir}_tmp"
			fi

			# 4)

		done

		# cleanup /tmp/TMP_REPO
		rm -rf "${TMP_REPO}"
		;;&
		
		#-------------------------------------------------------------------------------
	esac
done
