#!/bin/bash

################################################################################
# This script is for automating repetetive tasks 
# after installing new Linux system
# (eg: cloning git repositories, installing apps, setting vimrc/bashrc ...)

##########################################
## Developed by Martin Šafránek in 2018 ##
## email: martinsafranek1997@seznam.cz  ##
##########################################

# Particular sections of this script can be invoked passing argument/s
#	(multiple arguments can be passed at once)
# arguments: see [options] bellow

options="all terminal apps git_config git_clone"
# [all] executes every option
# [terminal] set gnome-terminal to open maximized for all users
# [apps] install list of applications using specified package manager
# [git_config] set git aliases, name, email, editor, enable loading git password into cache
# [git_clone] clone list of git repositories to home directory, if there
#	was bashrc/vimrc cloned, backup current bashrc/vimrc and replace it with cloned

# EXIT_VALUES
# [0] all OK
# [1] no arguments
# [2] invalid argument/s
# [3] no internet connection
################################################################################

function print_delimiter() {
	for i in {1..80}
	do
		echo -n "#"
	done
	echo
} 

function print_help() {
	>&2 echo "Usage: $0 <arg> ..."
	>&2 echo "Arguments are: $options"
	>&2 echo "Multiple arguments can be passed at once, [all] will pass every argument"
	>&2 echo "----------"
	>&2 echo "For more information open $0 with text editor"
}

function check_internet_conn {
	ping -w 1 -c 1 google.com > /dev/null 2>&1 
	if [ $? -ne 0 ]
	then
		print_delimiter
		>&2 echo "Internet connection needed"
		print_delimiter
		exit 3
	fi
}

# exit if there was no argument
if [ "$#" -eq 0 ]
then
	print_help
	exit 1
fi

# check if --help or -h was passed
if [ "$1" == "-h" -o "$1" == "--help" ]
then
	print_help
	exit 0
fi

# check for valid arguments
for arg in $@
do
	if [[ ! "$options" =~ (^|[[:space:]])"$arg"($|[[:space:]]) ]]
	then
		>&2 echo "'$arg' is invalid argument"
		>&2 echo "valid arguments are: $options"	
		exit 2
	fi
done


# TODO make local variables all-lowercase
# TODO trap clause
for arg in "$@"
do
	case "$arg" in

		#-------------------------------------------------------------------------------
		# 1) Set gnome-terminal to open mazimized
		terminal|all)

		echo "Setting gnome-terminal to open maximized . . ."
		sudo sed -i 's/^Exec=gnome-terminal$/Exec=gnome-terminal --window --maximize/' /usr/share/applications/org.gnome.Terminal.desktop
		echo ". . . done"
		print_delimiter
		;;&
		
		#-------------------------------------------------------------------------------
		# 2) Install necessary applications
		apps|all)

		PACMAN=""
		PACMAN_FLAGS=""
		APPS="vim git g++ gcc-c++ clang valgrind make htop glances aircrack-ng macchanger okular qbittorrent speedtest-cli youtube-dl xclip"

		echo "APPS: '$APPS'"
		echo "Install all[a], abort installation[q] or choose apps[c] to install ?"
		read -p ': ' ANS

		# choose
		if [[ "$ANS" =~ ^[cC]$ ]]
		then
			APPS_TMP=""
			echo "[q] for quit choosing"
			for app in $APPS
			do
				read -p "Install $app [y/n]? " ANS					
				if [[ "$ANS" =~ ^[Yy]$ ]]
				then
					APPS_TMP+="$app "
				elif [[ "$ANS" =~ ^[qQ]$ ]]
				then
					break
				fi
			done
			echo
			APPS="$APPS_TMP"

		# quit
		elif [[ "$ANS" =~ ^[qQ]$ ]]
			then
			APPS=""
		fi


		# install apps, if there are any
		if [ ! -z "$APPS" ]
		then
			if [ -z "$PACMAN" ]
			then
				read -p 'Package manager: ' PACMAN
			fi

			if [ -z "$PACMAN_FLAGS" ]
			then
				read -p 'Package flags: ' PACMAN_FLAGS
			fi

			# install apps, one by one
			for app in $APPS
			do
				sudo $PACMAN $PACMAN_FLAGS $app
			done
		else
			echo "Nothing to install!"
		fi
		
		print_delimiter
		;;&

		#-------------------------------------------------------------------------------
		# 3) Setup GIT
		git_config|all)
		GIT_NAME="Martin Safranek"
		GIT_EMAIL="martinsafranek1997@seznam.cz"
		GIT_EDITOR="vim"

		echo -n "Setting up git . . . "
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

		# keep password cached in memory for (by default) 15 minutes
		git config --global credential.helper cache

		echo "done"
		print_delimiter
		;;&

		#-------------------------------------------------------------------------------
		# 4) Fetch GIT reposiroties & copy them to home & setup bashrc and vimrc
		git_clone|all)

		HOME_DIR=""
		TMP_DIR='/tmp/git_repos_tmp'
		CLONED_DIRS="vimrc bashrc develop dokumenty"
		TIMESTAMP=$(date +%Y-%m-%d.%H:%M:%S)

		echo -e "Cloning git repositories and setting up vimrc/bashrc . . .\n"
		echo "REPOSITORIES: '$CLONED_DIRS'"

		# prompt to choose directories to clone
		CLONED_DIRS_TMP=""
		for dir in $CLONED_DIRS
		do
			read -p "Clone $dir [y/n]? " ANS
			if [[ $ANS =~ ^[Yy]$ ]]
			then
				CLONED_DIRS_TMP+="$dir "
			fi
		done

		CLONED_DIRS="$CLONED_DIRS_TMP"

		# clone directories, if there are any
		if [ ! -z "$CLONED_DIRS" ]
		then
			echo -e "\nCloning '$CLONED_DIRS' ..."

			# ask user for home directory
			if [ -z "$HOME_DIR" ]
			then
				HOME_DIR="$HOME"
				echo "Is '${HOME_DIR}' your home directory ?'"
				read -p "[y/n] " ANS

				if ! [[ "$ANS" =~ ^[Yy]$ ]]
				then
					read -p 'Enter home directory: ' HOME_DIR
				fi
			fi

			# create TMP_DIR
			if [ ! -d "${TMP_DIR}" ]
			then
				mkdir "${TMP_DIR}"
			fi

			cd "${TMP_DIR}"


			# Loop throw all CLONED_DIR and ...
			# a) Clone git repo to /tmp/TMP_DIR
			# b) Backup overlapping directory in HOME_DIR
			# c) Move cloned git repos from /tmp/TMP_DIR to HOME_DIR
			for dir in $CLONED_DIRS
			do

				# TODO make possible retry after wrong password
				# TODO add ssh option to .git/config
				# a) Clone git repo 
				git clone https://kaldomain@bitbucket.org/kaldomain/"${dir}".git 

				# b) If such directory exists in HOME_DIR, backup it
				if [ -d "${HOME_DIR}/${dir}" ]
				then
					mv "${HOME_DIR}/${dir}" "${HOME_DIR}/${dir}_$TIMESTAMP.bak"
				fi

				# c) move
				mv "${TMP_DIR}/${dir}" "${HOME_DIR}"
				print_delimiter
			done

			#------------------------------
			# Setup VIMRC
			
			# if there is vimrc to setup
			if [ -e "${HOME_DIR}/vimrc/vimrc" ]
			then
				echo -n "Setting up VIMRC . . . "

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

				echo "done"
				print_delimiter
			fi


			#------------------------------
			# Setup BASHRC

			# variable used to set the correct version of bashrc
			# 	-> bashrc_fedora, bashrc_arch, bashrc_ubuntu
			SYSTEM_ID=$(cat /etc/*-release | grep -E '^ID=' | head -n 1 |cut  -d'=' -f2)
			
			# if there is bashrc to setup
			if [ -e "${HOME_DIR}/bashrc/bashrc_${SYSTEM_ID}" ]
			then
				echo -n "Setting up BASHRC . . . "

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

				echo "done"
			fi
		else
			echo "There is nothing to clone!"
		fi

		# cleanup /tmp/TMP_DIR
		rm -rf "${TMP_DIR}"
		;;&
		
		#-------------------------------------------------------------------------------
	esac
done

exit 0
