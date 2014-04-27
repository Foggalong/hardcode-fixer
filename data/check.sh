#!/bin/bash

# Script for checking theme support for the hardcode fixer, maintained
# at https://github.com/Foggalong/hardcode-fixer  - addtions welcome!

# Copyright (C) 2014
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License (version 3+) as 
# published by the Free Software Foundation. You should have received
# a copy of the GNU General Public License along with this program. 
# If not, see <http://www.gnu.org/licenses/>.

# Data directory
data_dir="$HOME/.local/share/data/hcf"

while read line; do
	# Splits line into array
	IFS="|" read -a array <<< $line

	# The Required Icon Name
	icon=$(echo ${array[4]} | sed -e "s/\r//g")

	# Local Launchers
	if [ -f ${icon}* ]
	then
		echo "${icon}    | ✔ |"
	else
		echo "${icon}    | ✘ |"
	fi
done < "$data_dir/tofix.txt"