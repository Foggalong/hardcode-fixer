#!/bin/bash

# Base script for the safe hardcoded icon fixer.
# Copyright (C) 2014  Joshua Fogg

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License (version 3+) as 
# published by the Free Software Foundation. You should have received
# a copy of the GNU General Public License along with this program.  
# If not, see <http://www.gnu.org/licenses/>.

# Version
version="0.3-b"

# The script must run as root.
if [[ $UID -ne 0 ]]; then
	echo "$0 must be run as root"
	exit 1
fi

# Deals with the flags
while getopts "fuhv" arg; do
case $arg in
    # u) mode="u";; <-- potential for unfixing mode 
    h) echo -e "This is the sample help screen."
       echo -e "way for helpfulness!"
       exit 0;;
    v) echo "$(basename -- "$0") $version"
       exit 0
    esac
done

echo $mode

while read line; do
	# Splits line into array
	IFS="|" read -a array <<< $line
	# Readability renaming
	name=$(echo ${array[1]} | sed -e "s/\r//g")
	launcher="$name.desktop"
	current=$(echo ${array[2]} | sed -e "s/\r//g")
	newicon=$(echo ${array[3]} | sed -e "s/\r//g")
	# Local Launchers
	if [ -f "$HOME/.local/share/applications/$launcher" ]
	then
		if [ $current != "steam" ]
		then
			echo "Fixing $name..."
			cp "$current" "$HOME/.local/share/icons/hicolor/48x48/apps/$newicon"
			sed -i "s/$current/Icon=\ $newicon/g" "$HOME/.local/share/applications/$launcher"
		else
			echo "Fixing $name (steam)..."
			cp "/usr/share/icons/hicolor/48x48/apps/steam.png" "$HOME/.local/share/icons/hicolor/48x48/apps/$newicon"
			sed -i "s/Icon=steam/Icon=\ $newicon/g" "$HOME/.local/share/applications/$launcher"
			sed -i "s/= /=/g" "$HOME/.local/share/applications/$launcher" # <- dirty fix for space bug
		fi
	else
		: #pass
	fi
	# Global Launchers
	if [ -f "/usr/share/applications/$launcher" ]
	then
		echo "Fixing $name..."
		cp "$current" "/usr/share/share/icons/hicolor/48x48/apps/$newicon"
		sed -i "s/$current/Icon=\ $newicon/g" "/usr/share/icons/share/applications/$launcher"
	else
		: #pass
	fi
done < test.txt