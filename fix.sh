#!/bin/bash

# Script for fixing hardcoded icons. Written and maintained on GitHub
# at https://github.com/Foggalong/hardcode-fixer - addtions welcome!

# Copyright (C) 2014
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License (version 3+) as
# published by the Free Software Foundation. You should have received
# a copy of the GNU General Public License along with this program.
# If not, see <http://www.gnu.org/licenses/>.

version="0.8.2"
date=201405081 # [year][month][date][extra]
mode="fix"     # default

# Deals with the flags
if [ -z $1 ]
then
	: # pass
else
	case $1 in
		-l|--local)
			mode="local";;
		-r|--revert)
			echo "This will undo all changes previously made."
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
			echo -e "  -l, --local \t Only fixes local launchers."
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

# Prepare directory
data_directory="/home/${SUDO_USER:-$USER}/.local/share/hcf-data"
mkdir -p "$data_directory"

# Verify data directory creation and existence by entering command directory
cd "$data_directory" || echo "$0: Data directory does not exist or was not created." || exit 1

# Creates data directory file contents (fail-safe)
touch "$data_directory/fixed.txt"
touch "$data_directory/log.txt"

# Verifies if 'curl' is installed
if type "curl" >> "$data_directory/log.txt"
then
	: # pass
else
	echo -e "$0: This script requires 'curl' to be installed\r
		to fetch the required files and check for updates.\r
		Please install them and rerun this script."
	exit 1
fi

# Check for newer version
new_date=$(curl -s https://raw.githubusercontent.com/Foggalong/hardcode-fixer/master/data/date.txt)
if [ $date -lt $new_date ]
then
	echo -e "You're files are out of date\! Please go to\r
		https://github.com/Foggalong/hardcode-fixer\r
		and download the latest version\!"
	while true; do
		read -p "Do you want to continue? " answer
		case $answer in
			[Yy]* ) echo; break;;
			[Nn]* ) exit;;
			* ) echo "Please answer [Y/y]es or [N/n]o.";;
		esac
	done
fi

# Checks for newer version of list
if [ -f "$data_directory/version.txt" ]
then
	list_date=$(cat "$data_directory/version.txt")
	new_list_date=$(curl -s https://raw.githubusercontent.com/Foggalong/hardcode-fixer/master/data/list/version.txt)
	if [ $list_date -lt $new_list_date ]
	then
		# Downloads icon data from GitHub repository to data directory
		curl -s -o "$data_directory/version.txt" 'https://raw.githubusercontent.com/Foggalong/hardcode-fixer/master/data/list/version.txt'
		curl -s -o "$data_directory/tofix.txt" 'https://raw.githubusercontent.com/Foggalong/hardcode-fixer/master/data/list/tofix.txt'
	fi
else
	curl -s -o "$data_directory/version.txt" 'https://raw.githubusercontent.com/Foggalong/hardcode-fixer/master/data/list/version.txt'
	curl -s -o "$data_directory/tofix.txt" 'https://raw.githubusercontent.com/Foggalong/hardcode-fixer/master/data/list/tofix.txt'
fi

# Forces full user ownership and read/write permissions on the data directory and its contents.
chown -R "${SUDO_USER:-$USER}" "$data_directory" "$data_directory"/*
chmod -R 777 "$data_directory" "$data_directory"/*

# Checks for root
if [[ $UID -ne 0 ]] && [ $mode != "local" ]
then
	if [ "$mode" == "revert" ]
	then
		# Checks if local only reversion is appropriate
		if grep -Fxq "fix" "$data_directory/log.txt"
		then
			echo -e "This script was previously run as root and so"
			echo -e "running 'revert' without it will not properly"
			echo -e "reverse the changes that were made."
			sleep 3 # Enables error timeout when launched via 'Run in Terminal' command.
			exit 1
		else
			mode="l-revert"
		fi
	else
		# Script must be run as root to fix/revert any global changes
		echo "The script must be run as root to fix global launchers."
		while true; do
			read -p "Do you want to continue in local mode? " answer
			case $answer in
				[Yy]* ) mode="local"; break;;
				[Nn]* ) exit;;
				* ) echo "Please answer [Y/y]es or [N/n]o.";;
			esac
		done
	fi
fi

# Append mode to log file
echo "$mode" >> "$data_directory/log.txt"

# Fixing code
if [ "$mode" == "fix" ] || [ "$mode" == "local" ]
then
	echo "Fixing hardcoded icons..."

	# Splits line into array
	IFS="|"
	while read -r nul name launcher current new_icon
	do
		# Formatting corrections
		name=$(echo $name | sed -e "s/\r//g")
		launcher=$(echo $launcher.desktop | sed -e "s/\r//g")
		current=$(echo $current | sed -e "s/\r//g")
		new_icon=$(echo $new_icon | sed -e "s/\r//g")

		# Escape non-standard and special characters in file names by creating a new variable.
		old_icon="$current"
		old_icon="${old_icon//\\/\\\\}" # escape all backslashes first
		old_icon="${old_icon//\//\\/}" # escape slashes

		# Local & Steam launchers
		if [ -f "/home/${SUDO_USER:-$USER}/.local/share/applications/${launcher}" ]
		then
			if [ "${current}" != "steam" ]
			then
				# Local launchers
				if grep -Fxq "L: $launcher" "$data_directory/fixed.txt" # checks if already fixed
				then
					: # pass
				else
					if [ -f "$current" ] # checks if icon exists to copy
					then
						echo "L: Fixing $name..."
						cp "$current" "/home/${SUDO_USER:-$USER}/.local/share/icons/hicolor/48x48/apps/${new_icon}"
						sed -i "s/Icon=${old_icon}/Icon=${new_icon}/g" "/home/${SUDO_USER:-$USER}/.local/share/applications/${launcher}"
						echo "L: $launcher" >> "$data_directory/fixed.txt"
					fi
				fi
			else
				# Steam launchers
				if grep -Fxq "S: $launcher" "$data_directory/fixed.txt" # checks if already fixed
				then
					: # pass
				else
					if [ -f "/usr/share/icons/hicolor/48x48/apps/steam.png" ] # checks if steam icon exists to copy
					then
						echo "S: Fixing $name..."
						cp "/usr/share/icons/hicolor/48x48/apps/steam.png" "/home/${SUDO_USER:-$USER}/.local/share/icons/hicolor/48x48/apps/${new_icon}.png"
						sed -i "s/Icon=steam/Icon=${new_icon}/g" "/home/${SUDO_USER:-$USER}/.local/share/applications/${launcher}"
						echo "S: $launcher" >> "$data_directory/fixed.txt"
					fi
				fi
			fi
		fi

		# Global launchers
		if [ $mode != "local" ] && [ -f "/usr/share/applications/${launcher}" ]
		then
			if grep -Fxq "G: $launcher" $data_directory/fixed.txt # checks if already fixed
			then
				: # pass	
			else
				if [ -f "$current" ] # checks if icon exists to copy
				then
					echo "G: Fixing $name..."
					cp "$current" "/usr/share/icons/hicolor/48x48/apps/${new_icon}"
					sed -i "s/Icon=${old_icon}/Icon=${new_icon}/g" "/usr/share/applications/${launcher}"
					echo "G: $launcher" >> "$data_directory/fixed.txt"
				fi
			fi
		fi
	done < "$data_directory/tofix.txt"
# Reversion code
elif [ "$mode" == "revert" ] || [ "$mode" == "l-revert" ]
then
	echo "Reverting changes and cleaning up..."

	# Checks if data directory exists
	if [ -d "$data_directory" ]
	then
		if [ -f "${data_directory}/fixed.txt" ] && [ -f "${data_directory}/tofix.txt" ]
		then
			echo "Reverting hardcoded icons..."
			# Splits line into array
			IFS="|"
			while read -r nul name launcher current new_icon
			do
				# Formatting corrections
				name=$(echo $name | sed -e "s/\r//g")
				launcher=$(echo $launcher.desktop | sed -e "s/\r//g")
				current=$(echo $current | sed -e "s/\r//g")
				new_icon=$(echo $new_icon | sed -e "s/\r//g")

				old_icon="$current"
				old_icon="${old_icon//\\/\\\\}" # escape all backslashes first
				old_icon="${old_icon//\//\\/}" # escape slashes

				# Local revert
				if [ -f "/home/${SUDO_USER:-$USER}/.local/share/applications/${launcher}" ] && [ -f "${current}" ]
				then
					if grep -Fxq "L: $launcher" "$data_directory/fixed.txt" # checks if needs reverting
					then
						echo "F: Reverting $name..."
						rm -f "/home/${SUDO_USER:-$USER}/.local/share/icons/hicolor/48x48/apps/${new_icon}"*
						sed -i "s/Icon=${new_icon}/Icon=${old_icon}/g" "/home/${SUDO_USER:-$USER}/.local/share/applications/${launcher}"
						sed -i "s/L: ${launcher}//g" "$data_directory/fixed.txt"
					fi
				fi

				# Steam revert
				if [ -f "/home/${SUDO_USER:-$USER}/.local/share/applications/${launcher}" ] && [ -f "/usr/share/icons/hicolor/48x48/apps/steam.png" ]
				then
					if grep -Fxq "S: $launcher" "$data_directory/fixed.txt" # checks if needs reverting
					then
						echo "S: Reverting $name..."
						rm -f "/home/${SUDO_USER:-$USER}/.local/share/icons/hicolor/48x48/apps/${new_icon}"*
						sed -i "s/Icon=${new_icon}/Icon=${old_icon}/g" "/home/${SUDO_USER:-$USER}/.local/share/applications/${launcher}"
						sed -i "s/S: ${launcher}//g" "$data_directory/fixed.txt"
					fi
				fi

				# Global revert
				if [ $mode != "l-revert" ] && [ -f "/usr/share/applications/${launcher}" ] && [ -f "${current}" ]
				then
					if grep -Fxq "G: $launcher" "$data_directory/fixed.txt" # checks if needs reverting
					then
						echo "G: Reverting $name..."
						rm -f "/usr/share/icons/hicolor/48x48/apps/${new_icon}"*
						sed -i "s/Icon=${new_icon}/Icon=${old_icon}/g" "/usr/share/applications/${launcher}"
						sed -i "s/G: ${launcher}//g" "$data_directory/fixed.txt"
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
