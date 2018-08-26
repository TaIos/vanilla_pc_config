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

		GIT_PASSWORD="1d0b23cb1666aa615728510ea2ff3005" // TODO CHANGE PASSWOD ON BITBUCKET !!!
		CLONED_DIRS="vimrc bashrc develop dokumenty"
		CLONED_DIRS="vimrc bashrc develop" // TODO delete this line
		TMP_DIR='/tmp/git_repos_tmp'
		HOME_DIR='/home/slarty'
		TIMESTAMP=$(date +%Y-%m-%d.%H:%M:%S)

		# create TMP_DIR if it doesn't exist
		if [ ! -d "${TMP_DIR}" ]
		then
			mkdir "${TMP_DIR}"
		fi

		cd "${TMP_DIR}"

		if [ -z "$GIT_PASSWORD" ]
		then
			read -sp 'GIT password: ' GIT_PASSWORD
		fi

		# Enable if shell is not interpreting string as words 
		# (not splitting the string as individual words, interpreting as one string)
		#setopt shwordsplit

		# Loop throw all CLONED_DIR and ...
		# a) Clone git repo to /tmp/TMP_DIR
		# b) Create directory specified in CLONED_DIRS in HOME_DIR, if it dosn't exist
		# c) Copy cloned git repos from /tmp/TMP_DIR to directories in HOME_DIR
		for dir in $CLONED_DIRS
		do
			# a) Clone git repo
			git clone https://kaldomain:"${GIT_PASSWORD}"@bitbucket.org/kaldomain/"${dir}".git 

			# b) Create directory in HOME_DIR if it doesn't exist
			if [ ! -d "${HOME_DIR}/${dir}" ]
			then
				mkdir "${HOME_DIR}/${dir}"
			fi

			# c) Copy content from /tmp/TMP_DIR to directories in HOME_DIR
			#
			# if the target directory is not empty, backup it
			if [ ! -z "$(ls -A  "${HOME_DIR}/${dir}")" ]
			then
				mv "${HOME_DIR}/${dir}" "${HOME_DIR}/${dir}_old_$TIMESTAMP"
			fi

			# copy the content
			mv "${TMP_DIR}/${dir}/" "${HOME_DIR}/${dir}"
		done

		#------------------------------
		# Setup VIMRC
		#
		# backup old vimrc, if there is any
		if [ -e "${HOME_DIR}/.vimrc" ]
		then
			mv "${HOME_DIR}/.vimrc" "${HOME_DIR}/.vimrc_old_$TIMESTAMP"
		fi

		# backup .vimrc_dir, if there is any
		if [ -e "${HOME_DIR}/.vimrc_dir" ]
		then
			mv "${HOME_DIR}/.vimrc_dir" "${HOME_DIR}/.vimrc_dir_old_$TIMESTAMP"
		fi

		# create .vimrc_dir & copy all content to it
		mv "${HOME_DIR}/vimrc" "${HOME_DIR}/.vimrc_dir"

		# set symlink to vimrc
		ln -sf "${HOME_DIR}/.vimrc_dir/vimrc" "${HOME_DIR}/.vimrc" 


		#------------------------------
		# Setup BASHRC
		#
		# backup old bashrc, if there is any
		if [ -e "${HOME_DIR}/.bashrc" ]
		then
			mv "${HOME_DIR}/.bashrc" "${HOME_DIR}/.bashrc_old_$TIMESTAMP"
		fi

		# backup .bashrc_dir, if there is any
		if [ -e "${HOME_DIR}/.bashrc_dir" ]
		then
			mv "${HOME_DIR}/.bashrc_dir" "${HOME_DIR}/.bashrc_dir_old_$TIMESTAMP"
		fi

		# create .bashrc_dir & copy all content to it
		mv "${HOME_DIR}/bashrc" "${HOME_DIR}/.bashrc_dir"

		# set symlink to correct bashrc (bashrc_fedora, bashrc_arch, bashrc_ubuntu)
		$SYSTEM_ID=$(cat /etc/*-release | grep 'ID=' |cut  -d'=' -f2)
		ln -sf "${HOME_DIR}/.bashrc_dir/bashrc_$SYSTEM_ID" "${HOME_DIR}/.bashrc" 

		source "${HOME_DIR}/.bashrc"
		#------------------------------

		# cleanup /tmp/TMP_DIR
		rm -rf "${TMP_DIR}"
		;;&
		
		#-------------------------------------------------------------------------------
	esac
done
