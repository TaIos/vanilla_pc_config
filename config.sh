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
		echo
		;;&
		
		#-------------------------------------------------------------------------------
		# 2) Install necessary applications
		apps|all)

		check_internet_conn

		pacman=""
		pacman_flags=""
		apps="vim git g++ gcc-c++ clang valgrind make htop glances bash-completion aircrack-ng macchanger okular keepass.x86_64 keepass qbittorrent speedtest-cli youtube-dl xclip"

		echo "apps: '$apps'"
		echo "Install all[a], abort installation[q] or choose apps[c] to install ?"
		read -p ': ' ans

		# choose
		if [[ "$ans" =~ ^[cC]$ ]]
		then
			apps_tmp=""
			echo "[q] for quit choosing"
			for app in $apps
			do
				read -p "Install $app [y/n]? " ans					
				if [[ "$ans" =~ ^[Yy]$ ]]
				then
					apps_tmp+="$app "
				elif [[ "$ans" =~ ^[qQ]$ ]]
				then
					break
				fi
			done
			echo
			apps="$apps_tmp"

		# quit
		elif [[ "$ans" =~ ^[qQ]$ ]]
			then
			apps=""
		fi


		# install apps, if there are any
		if [ ! -z "$apps" ]
		then
			if [ -z "$pacman" ]
			then
				read -p 'Package manager: ' pacman
			fi

			if [ -z "$pacman_flags" ]
			then
				read -p 'Package flags: ' pacman_flags
			fi

			# install apps, one by one
			for app in $apps
			do
				sudo $pacman $pacman_flags $app
			done
		else
			echo "Nothing to install!"
		fi
		
		print_delimiter
		;;&

		#-------------------------------------------------------------------------------
		# 3) Setup GIT
		git_config|all)
		git_name="Martin Safranek"
		git_email="martinsafranek1997@seznam.cz"
		git_editor="vim"

		echo -n "Setting up git . . . "
		if [ -z "$git_name" ]
		then
			read -p 'Git name: ' git_name
		fi

		if [ -z "$git_email" ]
		then
			read -p 'Git email: ' git_email
		fi

		if [ -z "$git_editor" ]
		then
			read -p 'Git editor: ' git_editor
		fi

		git config --global user.name "$git_name"
		git config --global user.email "$git_email"
		git config --global core.editor "$git_editor"

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

		check_internet_conn

		home_dir=""
		tmp_dir='/tmp/git_repos_tmp'
		cloned_dirs="vimrc bashrc develop dokumenty"
		timestamp=$(date +%Y-%m-%d.%H%M)


		echo -e "Cloning git repositories and setting up vimrc/bashrc . . .\n"
		echo "REPOSITORIES: '$cloned_dirs'"

		# prompt to choose directories to clone
		cloned_dirs_tmp=""
		for dir in $cloned_dirs
		do
			read -p "Clone $dir [y/n]? " ans
			if [[ $ans =~ ^[Yy]$ ]]
			then
				cloned_dirs_tmp+="$dir "
			fi
		done

		cloned_dirs="$cloned_dirs_tmp"

		# if there is something to clone, proceed
		if [ ! -z "$cloned_dirs" ]
		then
			echo -e "\nCloning '$cloned_dirs' ..."

			# ask user for home directory 
			if [ -z "$home_dir" ]
			then
				home_dir="$HOME"
				echo "Is '${home_dir}' your home directory ?'"
				read -p "[y/n] " ans

				if ! [[ "$ans" =~ ^[Yy]$ ]]
				then
					read -p 'Enter home directory: ' home_dir
				fi
			fi

			# create tmp_dir for cloning git repositories
			if [ ! -d "${tmp_dir}" ]
			then
				mkdir "${tmp_dir}"
			fi

			# Loop throw all cloned_dir and ...
			# a) Clone git repo to /tmp/tmp_dir
			# b) Backup overlapping directory in home_dir
			# c) Move cloned git repositories from /tmp/tmp_dir to home_dir
			for dir in $cloned_dirs
			do

				# TODO add ssh option to .git/config
				# a) Clone git repo, with fail check
				while true
				do
					clone_st=true
					git -C "${tmp_dir}" clone https://kaldomain@bitbucket.org/kaldomain/"${dir}".git 
					if [ $? -ne 0 ]
					then
						clone_st=false
						echo "Cloning '${dir}' into '${tmp_dir}' failed"
						echo
						read -p "Retry cloning '${dir}' [y/n]? :" ans
						if [[ "$ans" =~ ^[yY]$ ]]
						then
							continue
						fi
					fi
					break
				done

				# if cloning was not succesfull, go to the next in list
				if [ "$clone_st" = false  ]
				then
					echo
					continue
				fi

				# b) If such directory exists in home_dir, backup it
				if [ -d "${home_dir}/${dir}" ]
				then
					mv "${home_dir}/${dir}" "${home_dir}/${dir}_$timestamp.bak"
				fi

				# c) move
				mv "${tmp_dir}/${dir}" "${home_dir}"
				print_delimiter
			done

			#------------------------------
			# Setup VIMRC
			
			# if there is vimrc to setup
			if [ -e "${home_dir}/vimrc/vimrc" ]
			then
				echo -n "Setting up VIMRC . . . "

				# backup old vimrc, if there is any
				if [ -e "${home_dir}/.vimrc" ]
				then
					mv "${home_dir}/.vimrc" "${home_dir}/.vimrc_$timestamp.bak"
				fi

				# backup old .vimrc_dir, if there is any
				if [ -e "${home_dir}/.vimrc_dir" ]
				then
					mv "${home_dir}/.vimrc_dir" "${home_dir}/.vimrc_dir_$timestamp.bak"
				fi

				# create .vimrc_dir & copy all content to it
				mv "${home_dir}/vimrc" "${home_dir}/.vimrc_dir"

				# set symlink to vimrc
				ln -sf "${home_dir}/.vimrc_dir/vimrc" "${home_dir}/.vimrc" 

				echo "done"
				print_delimiter
			fi


			#------------------------------
			# Setup BASHRC

			# variable used to set the correct version of bashrc
			# 	-> bashrc_fedora, bashrc_arch, bashrc_ubuntu
			system_id=$(cat /etc/*-release | grep -E '^ID=' | head -n 1 |cut  -d'=' -f2)
			
			# if there is bashrc to setup
			if [ -e "${home_dir}/bashrc/bashrc_${system_id}" ]
			then
				echo -n "Setting up BASHRC . . . "

				# backup old bashrc, if there is any
				if [ -e "${home_dir}/.bashrc" ]
				then
					mv "${home_dir}/.bashrc" "${home_dir}/.bashrc_$timestamp.bak"
				fi

				# backup old .bashrc_dir, if there is any
				if [ -e "${home_dir}/.bashrc_dir" ]
				then
					mv "${home_dir}/.bashrc_dir" "${home_dir}/.bashrc_dir_$timestamp.bak"
				fi

				# create .bashrc_dir & copy all content to it
				mv "${home_dir}/bashrc" "${home_dir}/.bashrc_dir"

				# set symlink to correct bashrc 
				ln -sf "${home_dir}/.bashrc_dir/bashrc_${system_id}" "${home_dir}/.bashrc" 

				echo "done"
			fi
		else
			echo "There is nothing to clone!"
		fi

		# cleanup /tmp/tmp_dir
		rm -rf "${tmp_dir}"
		;;&
		
		#-------------------------------------------------------------------------------
	esac
done

exit 0
