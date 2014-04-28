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
version="0.6"

# Default mode
mode="fix"

# Deals with the flags
if [ -z $1 ]
then
	: # pass
else
	case $1 in
		-r|--revert)
			echo -e "This will undo all changes previously made."
			while true; do
				read -p "Are you sure you want to continue? " answer
				case $answer in
					[Yy]* ) mode="revert"; break;;
					[Nn]* ) exit;;
					* ) echo "Please answer [Y/y]es or [N/n]o.";;
				esac
			done;;
		-h|--help)
			echo -e "Usage: ./$(basename -- $0) [OPTION]"
			echo -e "Fixes hardcoded icons of installed applications."
			echo -e ""
			echo -e "Currently supported options:"
			echo -e "  -r, --revert \t Reverts any changes made."
			echo -e "  -h, --help \t\t Displays this help menu."
			echo -e "  -v, --version \t Displays program version."
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

# Script must be run as root to fix/revert any changes
if [[ $UID -ne 0 ]]
then
	echo "$0: This script must be run as root."
	echo "Please relaunch the script as superuser."
	sleep 3 # Enables error timeout when launched via 'Run in Terminal' command.
	exit 1
fi

# Data directory
data_directory="/home/${SUDO_USER:-$USER}/.local/share/data/hcf"

# Fixing code
if [ "$mode" == "fix" ]
then
	echo "Fixing hardcoded icons..."

	# Creates data directory & file
	mkdir -p "$data_directory"
	touch "$data_directory/fixed.txt"
	chmod -R 777 "$data_directory" # Forces full read/write permissions on the data directory and its contents.

	# Verify data directory creation and existence by entering command directory
	cd "$data_directory" || echo "$0: Data directory does not exist or was not created." || exit 1

	# Downloads icon data from GitHub repository to data directory
	if type "wget" > /dev/null 2>&1 # Verifies if 'wget' is installed
	then
		wget -O "$data_directory/tofix.txt" 'https://raw.githubusercontent.com/Foggalong/hardcode-fixer/master/data/tofix.txt'
	elif type "curl"  > /dev/null 2>&1 # Verifies if 'curl' is installed, provided 'wget' isn't
	then
		curl -O "$data_directory/tofix.txt" 'https://raw.githubusercontent.com/Foggalong/hardcode-fixer/master/data/tofix.txt'
	else
		echo "$0: This script requires either 'wget' or 'curl' to be installed to fetch the required files. Please install them and rerun this script."
		exit 1
	fi

	while read line; do
		# Splits line into array
		IFS="|" read -a array <<< $line
		# Readability renaming
		name=$(echo ${array[1]} | sed -e "s/\r//g")
		launcher=$(echo ${array[2]}.desktop | sed -e "s/\r//g")
		current=$(echo ${array[3]} | sed -e "s/\r//g")
		new_icon=$(echo ${array[4]} | sed -e "s/\r//g")

		# Escape non-standard and special characters in file names by creating a new variable.
		old_icon="$current"
		old_icon="${old_icon//\\/\\\\}" # escape all backslashes first
		old_icon="${old_icon//\//\\/}" # escape slashes

		# Local launchers
		if [ -f "$HOME/.local/share/applications/${launcher}" ]
		then
			if grep -Fxq "$name" "$data_directory/fixed.txt" # checks if already fixed
			then
				: # pass
			else
				if [ "${current}" != "steam" ]
				then
					if [ -f "$current" ] # checks if icon exists to copy
					then
						echo "L: Fixing $name..."
						cp "$current" "$HOME/.local/share/icons/hicolor/48x48/apps/${new_icon}"
						sed -i "s/Icon=${old_icon}/Icon=${new_icon}/g" "$HOME/.local/share/applications/${launcher}"
						echo "$name" >> "$data_directory/fixed.txt"
					fi
				else
					echo "L: Fixing $name (steam)..."
					cp "/usr/share/icons/hicolor/48x48/apps/steam.png" "$HOME/.local/share/icons/hicolor/48x48/apps/${new_icon}.png"
					sed -i "s/Icon=steam/Icon=${new_icon}/g" "$HOME/.local/share/applications/${launcher}"
					echo "$name" >> "$data_directory/fixed.txt"
				fi
			fi
		fi

		# Global launchers
		if [ -f "/usr/share/applications/${launcher}" ]
		then
			if grep -Fxq "$name" $data_directory/fixed.txt # checks if already fixed
			then
				: # pass
			else
				if [ -f "$current" ] # checks if icon exists to copy
				then
					echo "G: Fixing $name..."
					cp "$current" "/usr/share/icons/hicolor/48x48/apps/${new_icon}"
					sed -i "s/Icon=${old_icon}/Icon=${new_icon}/g" "/usr/share/applications/${launcher}"
					echo "$name" >> "$data_directory/fixed.txt"
				fi
			fi
		fi
	done < "$data_directory/tofix.txt"
# Reversion code
elif [ "$mode" == "revert" ]
then
	echo "Reverting changes and cleaning up..."

	# Checks if data directory exists
	if [ -d "$data_directory" ]
	then
		if [ -f "${data_directory}/fixed.txt" ] && [ -f "${data_directory}/tofix.txt" ]
		then
			echo -e "\nReverting hardcoded icons..."
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

				# Local revert
				if [ -f "$HOME/.local/share/applications/${launcher}" ]
				then
					if grep -Fxq "$name" "$data_directory/fixed.txt" # checks if needs reverting
					then
						echo "F: Unixing $name..."
						rm -f "$HOME/.local/share/icons/hicolor/48x48/apps/${new_icon}"*
						sed -i "s/Icon=${new_icon}/Icon=${old_icon}/g" "$HOME/.local/share/applications/${launcher}"
					fi
				fi

				# Global revert
				if [ -f "/usr/share/applications/${launcher}" ]
				then
					if grep -Fxq "$name" "$data_directory/fixed.txt" # checks if needs reverting
					then
						echo "G: reverting $name..."
						rm -f "/usr/share/icons/hicolor/48x48/apps/${new_icon}"*
						sed -i "s/Icon=${new_icon}/Icon=${old_icon}/g" "/usr/share/applications/${launcher}"
					fi
				fi
			done < "$data_directory/tofix.txt"

			# Removing files and directories
			rm -rf $data_directory
			echo "Deleted data directory. Clean up complete!"
			exit 0
		else
			echo "Data files do not exist, so icon changes"
			echo "cannot be reverted (or were never made)."
			rm -rf $data_directory
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
