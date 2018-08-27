#!/bin/bash

## This script is for automating repetetive tasks 
## after installing new Linux system

## Particular sections can be invoked passing argument/s
## arguments: all, terminal, apps, git_config, git_fetch


echo "Testing for internet connection ..."
ping -c 3 google.com > /dev/null 2>&1 
if [ $? -ne 0 ]
then
	echo "Internet connectivity needed to run this script."
	exit 666
fi

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

		PACMAN=""
		PACMAN_FLAGS=""
		APPS="vim git g++ gcc-c++ clang valgrind make htop glances aircrack-ng macchanger okular qbittorrent speedtest-cli youtube-dl xclip"

		if [ -z "$PACMAN" ]
		then
			read -p 'Package manager: ' PACMAN
		fi

		if [ -z "$PACMAN_FLAGS" ]
		then
			read -p 'Package flags: ' PACMAN_FLAGS
		fi

		# Enable if shell is not interpreting string as words 
		# (not splitting the string as individual words, interpreting as one string)
		#setopt shwordsplit

		for app in $APPS
		do
			sudo $PACMAN $PACMAN_FLAGS $app
		done

		;;&

		#-------------------------------------------------------------------------------
		# 3) Setup GIT
		git_config|all)
		GIT_NAME="Martin Safranek"
		GIT_EMAIL="martinsafranek1997@seznam.cz"
		GIT_EDITOR="vim"

		if [ -z "$GIT_NAME" ]
		then
			read -p 'Git name: ' GIT_NAME
		fi

		if [ -z "$GIT_EMAIL" ]
		then
			read -p 'Git email: ' GIT_EMAIL
		fi

		if [ -z "$GIT_EDITOR" ]
		then
			read -p 'Git editor: ' GIT_EDITOR
		fi

		git config --global user.name "$GIT_NAME"
		git config --global user.email "$GIT_EMAIL"
		git config --global core.editor "$GIT_EDITOR"

		git config --global alias.co checkout
		git config --global alias.br branch
		git config --global alias.ci commit
		git config --global alias.st status
		git config --global alias.ll 'log --oneline --graph --all --decorate'
		;;&

		#-------------------------------------------------------------------------------
		# 4) Fetch GIT reposiroties & copy them to home & setup bashrc and vimrc
		git_clone|all)

		HOME_DIR=""
		TMP_DIR='/tmp/git_repos_tmp'
		CLONED_DIRS="vimrc bashrc develop dokumenty"
		GIT_PASSWORD="1d0b23cb1666aa615728510ea2ff3005" # TODO CHANGE PASSWOD ON BITBUCKET !!!
		TIMESTAMP=$(date +%Y-%m-%d.%H:%M:%S)

		# prompt to choose directories to clone
		CLONED_DIRS_TMP=""
		for dir in $CLONED_DIRS
		do
			read -p 'Clone $dir [Y/N]? ' ANS
			if [[ $ANS =~ ^[Yy]$ ]]
			then
				CLONED_DIRS_TMP+="$dir "
			fi
		done

		CLONED_DIRS="$CLONED_DIRS_TMP"
		echo "Cloning $CLONED_DIRS ..."


		# ask user for home directory
		if [ -z "$HOME_DIR" ]
		then
			HOME_DIR="$HOME"
			read -p "Is this your home directory: $HOME_DIR\n[Y/N]: " ANS

			if ! [[ "$ANS" =~ ^[Yy]$ ]]
			then
				read -p 'Enter home directory: ' HOME_DIR
			fi
		fi

		if [ -z "$GIT_PASSWORD" ]
		then
			read -sp 'GIT password: ' GIT_PASSWORD
		fi

		# create TMP_DIR
		if [ ! -d "${TMP_DIR}" ]
		then
			mkdir "${TMP_DIR}"
		fi

		cd "${TMP_DIR}"


		# Enable if shell is not interpreting string as words 
		# (not splitting the string as individual words, interpreting as one string)
		#setopt shwordsplit

		# Loop throw all CLONED_DIR ...
		# a) Clone git repo to /tmp/TMP_DIR
		# b) Backup overlapping directory in HOME_DIR
		# c) Move cloned git repos from /tmp/TMP_DIR to HOME_DIR
		for dir in $CLONED_DIRS
		do
			# a) Clone git repo
			git clone https://kaldomain:"${GIT_PASSWORD}"@bitbucket.org/kaldomain/"${dir}".git 

			# b) If such directory exists in HOME_DIR, backup it
			if [ -d "${HOME_DIR}/${dir}" ]
			then
				mv "${HOME_DIR}/${dir}" "${HOME_DIR}/${dir}_$TIMESTAMP.bak"
			fi

			# c) move
			mv "${TMP_DIR}/${dir}" "${HOME_DIR}"
		done

		#------------------------------
		# Setup VIMRC
		
		# if there is vimrc to setup
		if [ -e "${HOME_DIR}/vimrc/vimrc" ]
		then
			# backup old vimrc, if there is any
			if [ -e "${HOME_DIR}/.vimrc" ]
			then
				mv "${HOME_DIR}/.vimrc" "${HOME_DIR}/.vimrc_$TIMESTAMP.bak"
			fi

			# backup old .vimrc_dir, if there is any
			if [ -e "${HOME_DIR}/.vimrc_dir" ]
			then
				mv "${HOME_DIR}/.vimrc_dir" "${HOME_DIR}/.vimrc_dir_$TIMESTAMP.bak"
			fi

			# create .vimrc_dir & copy all content to it
			mv "${HOME_DIR}/vimrc" "${HOME_DIR}/.vimrc_dir"

			# set symlink to vimrc
			ln -sf "${HOME_DIR}/.vimrc_dir/vimrc" "${HOME_DIR}/.vimrc" 
		fi


		#------------------------------
		# Setup BASHRC

		# variable used to set the correct version of bashrc
		# 	-> bashrc_fedora, bashrc_arch, bashrc_ubuntu
		SYSTEM_ID=$(cat /etc/*-release | grep -E '^ID=' | head -n 1 |cut  -d'=' -f2)
		
		# if there is bashrc to setup
		if [ -e "${HOME_DIR}/bashrc/bashrc_${SYSTEM_ID}" ]
		then
			# backup old bashrc, if there is any
			if [ -e "${HOME_DIR}/.bashrc" ]
			then
				mv "${HOME_DIR}/.bashrc" "${HOME_DIR}/.bashrc_$TIMESTAMP.bak"
			fi

			# backup old .bashrc_dir, if there is any
			if [ -e "${HOME_DIR}/.bashrc_dir" ]
			then
				mv "${HOME_DIR}/.bashrc_dir" "${HOME_DIR}/.bashrc_dir_$TIMESTAMP.bak"
			fi

			# create .bashrc_dir & copy all content to it
			mv "${HOME_DIR}/bashrc" "${HOME_DIR}/.bashrc_dir"

			# set symlink to correct bashrc 
			ln -sf "${HOME_DIR}/.bashrc_dir/bashrc_${SYSTEM_ID}" "${HOME_DIR}/.bashrc" 
		fi

		#------------------------------

		# cleanup /tmp/TMP_DIR
		rm -rf "${TMP_DIR}"
		;;&
		
		#-------------------------------------------------------------------------------
	esac
done
