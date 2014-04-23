#!/bin/bash

# Base script for the safe hardcoded icon fixer.
# Copyright (C) 2014 Joshua Fogg

# Edited 23-04-2014 by Nathanel Titane (nathanel.titane@gmail.com)
# Bash standards compliancy and comment cleanup
# Added data directory creation/existence verification before launching fix

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License (version 3+) as 
# published by the Free Software Foundation. You should have received
# a copy of the GNU General Public License along with this program. 
# If not, see <http://www.gnu.org/licenses/>.

# Version
version="0.3.3"

# Data directory
data_dir="$HOME/.local/share/data/hcf"

# The script must be run as root
if [[ $UID -ne 0 ]]
then
	echo "$0: This script must be run as root."
	sleep 3 # Enables error timeout when script is launched via 'Run in Terminal' command.
	exit 1
fi

# Deals with the flags
while getopts "hv" arg; do
case $arg in
#	u) echo -e "Undo changes." # Eventual 'Undo' selection
	h) echo -e "This is the sample help screen."
		echo -e "way for helpfulness!"
		exit 0;;
	v) echo "$(basename -- $0) $version"
		exit 0
	esac
done

# Creates data directory & file
if [ -f "$data_dir" ]
then
	: # pass
else
	mkdir -p "$data_dir"
	touch "$data_dir/fixed.txt"
fi

# Verify data directory creation and existence by entering command directory
cd "$data_dir" || echo "$0: Data directory does not exist or was not created." || exit 1

# Downloads icon data from GitHub repository to data directory
wget -O "$data_dir/tofix.txt" 'https://raw.githubusercontent.com/Foggalong/hardcode-fixer/master/data/tofix.txt'

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
					cp "$current" "$HOME/.local/share/icons/hicolor/48x48/apps/"
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
				cp "$current" "/usr/share/icons/hicolor/48x48/apps/"
				sed -i "s/${old_icon}/${new_icon}/g" "/usr/share/applications/${launcher}"
				echo "$name" >> "$data_dir/fixed.txt"
			fi
		fi
	fi

done < "$data_dir/tofix.txt"
