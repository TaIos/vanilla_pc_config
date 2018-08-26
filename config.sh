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

		GIT_PASSWORD="1d0b23cb1666aa615728510ea2ff3005"
		CLONED_DIRS="vimrc bashrc develop dokumenty"
		CLONED_DIRS="vimrc bashrc develop"
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

		# 1) Clone git repo to /tmp/TMP_DIR
		# 2) Create dir specified in CLONED_DIRS in HOME_DIR, if dosn't exist
		# 3) Copy cloned git repos from /tmp/TMP_DIR to created? dir in HOME_DIR
		# 4) Setup vimrc
		# 5) Setup bashrc
		for dir in $CLONED_DIRS
		do

			# 1) Clone git repo
			git clone https://kaldomain:"${GIT_PASSWORD}"@bitbucket.org/kaldomain/"${dir}".git 


			# 2) Create dir if not exist
			if [ ! -d "${HOME_DIR}/${dir}" ]
			then
				mkdir "${HOME_DIR}/${dir}"
			fi


			# 3) Copy to dir
			# if the target directory is not empty, backup it
			if [ ! -z "$(ls -A  "${HOME_DIR}/${dir}")" ]
			then
				mv "${HOME_DIR}/${dir}" "${HOME_DIR}/${dir}_old_$TIMESTAMP"
				mkdir "${HOME_DIR}/${dir}"
			fi
			# copy the content
			cp -r "${TMP_DIR}/${dir}/"* "${HOME_DIR}/${dir}"

			
			# 4) Setup vimrc
			# backup old vimrc, if there is any
			if [ -e "${HOME_DIR}/.vimrc" ]
			then
				mv "${HOME_DIR}/.vimrc" "${HOME_DIR}/.vimrc_old_$TIMESTAMP"
			fi

			# if there is .vimrc_dir, backup it
			if [ -e "${HOME_DIR}/.vimrc_dir" ]
			then
				mv "${HOME_DIR}/.vimrc_dir" "${HOME_DIR}/.vimrc_dir_old_$TIMESTAMP"
			fi

			# create .vimrc_dir & copy all content to it
			mkdir "${HOME_DIR}/.vimrc_dir"
			mv "${HOME_DIR}/vimrc/"* "${HOME_DIR}/.vimrc_dir"

			# set symlink to vimrc
			ln -s "${HOME_DIR}/.vimrc" "${HOME_DIR}/.vimrc_dir/vimrc"

			#cleanup
			rm -rf "${HOME_DIR}/vimrc"


			# 5) Setup bashrc
			# backup old bashrc, if there is any
			if [ -e "${HOME_DIR}/.bashrc" ]
			then
				mv "${HOME_DIR}/.bashrc" "${HOME_DIR}/.bashrc_old_$TIMESTAMP"
			fi

			# if there is .bashrc_dir, backup it
			if [ -e "${HOME_DIR}/.bashrc_dir" ]
			then
				mv "${HOME_DIR}/.bashrc_dir" "${HOME_DIR}/.bashrc_dir_old_$TIMESTAMP"
			fi

			# create .bashrc_dir & copy all content to it
			mkdir "${HOME_DIR}/.bashrc_dir"
			mv "${HOME_DIR}/bashrc/"* "${HOME_DIR}/.bashrc_dir"

			# set symlink to correct bashrc (bashrc_fedora|bashrc_arch|bashrc_ubuntu)
			$SYSTEM_ID=$(cat /etc/*-release | grep 'ID=' |cut  -d'=' -f2)
			ln -s "${HOME_DIR}/.bashrc" "${HOME_DIR}/.bashrc_dir/bashrc_$SYSTEM_ID"

			#cleanup
			rm -rf "${HOME_DIR}/bashrc"
		done

		# cleanup /tmp/TMP_DIR
		rm -rf "${TMP_DIR}"
		;;&
		
		#-------------------------------------------------------------------------------
	esac
done
