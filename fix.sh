#!/bin/bash

# Script for fixing hardcoded icons. Written and maintained on GitHub
# at https://github.com/Foggalong/hardcode-fixer  - addtions welcome!

# Copyright (C) 2014
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License (version 3+) as 
# published by the Free Software Foundation. You should have received
# a copy of the GNU General Public License along with this program. 
# If not, see <http://www.gnu.org/licenses/>.

# Version
version="0.5.1"

# Default Mode
mode="fix"

# Deals with the flags
if [ -z $1 ] 
then
	:
else
	case $1 in
		-u|--unfix) 
			echo -e "This will undo all changes previously made."
			while true; do
				read -p "Are you sure you want to continue? " yn
				case $yn in
					[Yy]* ) mode="unfix"; break;;
					[Nn]* ) exit;;
					* ) echo "Please answer yes or no.";;
				esac
			done;;
		-h|--help) 
			echo -e "Usage: ./$(basename -- $0) [OPTION]"
			echo -e "Fixes hardcoded icons of installed applications"
			echo -e ""
			echo -e "Currently supported options"
			echo -e "  -u, --unfix \t Reverts any changes made"
			echo -e "  -h, --help \t\t Displays this help menu" 
			echo -e "  -v, --version \t Displays program version"
			exit 0 ;;
		-v|--version) 
			echo "$(basename -- $0) $version\n"
			exit 0 ;;
		*) 
			echo -e "$(basename -- $0): invalid option -- '$1'"
			echo -e "Try '$(basename -- $0) --help' for more information."
			exit 0 ;;
	esac
fi

# Script must be run as root to fix/unfix
if [[ $UID -ne 0 ]]
then
	echo "$0: This script must be run as root."
	sleep 3 # Enables error timeout when launched via 'Run in Terminal' command.
	exit 1
fi

# Data directory
data_dir="$HOME/.local/share/data/hcf"

if [ "$mode" == "fix" ]
then
	echo -e "\nFixing hardcoded icons..."

	# Creates data directory & file
	mkdir -p "$data_dir"
	touch "$data_dir/fixed.txt"

	# Verify data directory creation and existence by entering command directory
	cd "$data_dir" || echo "$0: Data directory does not exist or was not created." || exit 1

	# Downloads icon data from GitHub repository to data directory
	if type "wget" > /dev/null 2>&1
	then
		wget -O "$data_dir/tofix.txt" 'https://raw.githubusercontent.com/Foggalong/hardcode-fixer/master/data/tofix.txt'
	else
		echo -e "$0: To use this script, you need to install 'wget'"
		exit 0
	fi

	while read line; do
		# Splits line into array
		IFS="|" read -a array <<< $line
		# Readability renaming
		name=$(echo ${array[1]} | sed -e "s/\r//g")
		launcher=$(echo ${array[2]}.desktop | sed -e "s/\r//g")
		current=$(echo ${array[3]} | sed -e "s/\r//g")
		new_icon=$(echo ${array[4]} | sed -e "s/\r//g")

		# Escape non-standard and special characters in file names by creating new variable
		old_icon="$current"
		old_icon="${old_icon//\\/\\\\}" # escape all backslashes first
		old_icon="${old_icon//\//\\/}" # escape slashes

		# Local Launchers
		if [ -f "$HOME/.local/share/applications/${launcher}" ]
		then
			if grep -Fxq "$name" "$data_dir/fixed.txt" # checks if already fixed
			then
				: # pass
			else
				if [ "${current}" != "steam" ]
				then
					if [ -f "$current" ] # checks if icon exists to copy
					then
						echo "L: Fixing $name..."
						cp "$current" "$HOME/.local/share/icons/hicolor/48x48/apps/${new_icon}"
						sed -i "s/${old_icon}/${new_icon}/g" "$HOME/.local/share/applications/${launcher}"
						echo "$name" >> "$data_dir/fixed.txt"
					fi
				else
					echo "L: Fixing $name (steam)..."
					cp "/usr/share/icons/hicolor/48x48/apps/steam.png" "$HOME/.local/share/icons/hicolor/48x48/apps/${new_icon}.png"
					sed -i "s/Icon=steam/Icon=${new_icon}/g" "$HOME/.local/share/applications/${launcher}"
					echo "$name" >> "$data_dir/fixed.txt"
				fi
			fi
		fi

		# Global Launchers
		if [ -f "/usr/share/applications/${launcher}" ]
		then
			if grep -Fxq "$name" $data_dir/fixed.txt # checks if already fixed
			then
				: # pass
			else
				if [ -f "$current" ] # checks if icon exists to copy
				then
					echo "G: Fixing $name..."
					cp "$current" "/usr/share/icons/hicolor/48x48/apps/${new_icon}"
					sed -i "s/${old_icon}/${new_icon}/g" "/usr/share/applications/${launcher}"
					echo "$name" >> "$data_dir/fixed.txt"
				fi
			fi
		fi
	done < "$data_dir/tofix.txt"
elif [ "$mode" == "unfix" ]
then
	echo -e "Begining clean up..."

	# Checks data directory exists
	if [ -d "$data_dir" ]
	then
		if [ -f "${data_dir}/fixed.txt" ] && [ -f "${data_dir}/tofix.txt" ]
		then
			echo -e "\nUnfixing hardcoded icons..."
			while read line; do
				IFS="|" read -a array <<< $line
				# Readability renaming
				name=$(echo ${array[1]} | sed -e "s/\r//g")
				launcher=$(echo ${array[2]}.desktop | sed -e "s/\r//g")
				current=$(echo ${array[3]} | sed -e "s/\r//g")
				new_icon=$(echo ${array[4]} | sed -e "s/\r//g")		

				old_icon="$current"
				old_icon="${old_icon//\\/\\\\}" # escape all backslashes first
				old_icon="${old_icon//\//\\/}" # escape slashes

				# Local unfixing
				if [ -f "$HOME/.local/share/applications/${launcher}" ]
				then
					if grep -Fxq "$name" "$data_dir/fixed.txt" # checks if need unfixing
					then
						echo "F: Unixing $name..."
						rm -f "$HOME/.local/share/icons/hicolor/48x48/apps/${new_icon}"*
						sed -i "s/${new_icon}/${old_icon}/g" "$HOME/.local/share/applications/${launcher}"
					fi
				fi

				# Global unfixing
				if [ -f "/usr/share/applications/${launcher}" ]
				then
					if grep -Fxq "$name" "$data_dir/fixed.txt" # checks if need unfixing
					then
						echo "G: Unixing $name..."
						rm -f "/usr/share/icons/hicolor/48x48/apps/${new_icon}"*
						sed -i "s/${new_icon}/${old_icon}/g" "/usr/share/applications/${launcher}"
					fi
				fi
			done < "$data_dir/tofix.txt"
			# Removing Evidence
			rm -rf $data_dir
			echo "Deleted data directory. Clean up complete!" 
			exit 0
		else
			echo "Data files do not exist, so icon changes"
			echo "cannot be reverted (or were never made)."
			rm -rf $data_dir
			echo "Deleted data directory. Clean up complete!" 
			exit 0
		fi
	else
		echo "Data directory doens't exist, so icon changes"
		echo "cannot be reverted (or were never made)."
		echo "Clean up cannot be performed!"
		exit 0
	fi
fi
