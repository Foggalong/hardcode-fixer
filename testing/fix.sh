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
while getopts "hv" arg; do
case $arg in
    # u) mode="u";; <-- potential for unfixing mode 
    h) echo -e "This is the sample help screen."
       echo -e "way for helpfulness!"
       exit 0;;
    v) echo "$(basename -- "$0") $version"
       exit 0
    esac
done

# Downloads icon data from GitHub to /tmp/
wget -O /tmp/test.txt https://raw.githubusercontent.com/Foggalong/hardcode-fixer/master/testing/test.txt

while read line; do
	# Splits line into array
	IFS="|" read -a array <<< $line
	# Readability renaming
	name=$(echo ${array[1]} | sed -e "s/\r//g")
	launcher="${name}.desktop"
	current=$(echo ${array[2]} | sed -e "s/\r//g")
	newicon=$(echo ${array[3]} | sed -e "s/\r//g")
	#
	# Problem with spec. chars. in file names solved by
	# creating a seperate var. that escapes them
	oldicon=$current
    oldicon="${oldicon//\\/\\\\}" # <- escape all backslashes first
    oldicon="${oldicon//\//\\/}"  # <- escape slashes
	#
	# Local Launchers
	if [ -f "$HOME/.local/share/applications/${launcher}" ]
	then
		if [ "${current}" != "steam" ]
		then
			if [ -f "$current" ]
			then
				echo "L: Fixing $name..."
				cp "$current" "$HOME/.local/share/icons/hicolor/48x48/apps/"
				sed -i "s/${oldicon}/${newicon}/g" "$HOME/.local/share/applications/${launcher}"
			fi
		else
			echo "L: Fixing $name (steam)..."
			cp "/usr/share/icons/hicolor/48x48/apps/steam.png" "$HOME/.local/share/icons/hicolor/48x48/apps/${newicon}.png"
			sed -i "s/Icon=steam/Icon=${newicon}/g" "$HOME/.local/share/applications/${launcher}"
		fi
	else
		: #pass 
	fi
	# Global Launchers
	if [ -f "/usr/share/applications/${launcher}" ]
	then
		if [ -f "$current" ]
		then
			echo "G: Fixing $name..."
			cp "$current" "/usr/share/icons/hicolor/48x48/apps/"
			sed -i "s/${oldicon}/${newicon}/g" "/usr/share/applications/${launcher}"
		fi
	else
		: #pass
	fi
done < /tmp/test.txt