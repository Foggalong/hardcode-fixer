#!/bin/bash

# Script for fixing hardcoded icons. Written and maintained on GitHub
# at https://github.com/Foggalong/hardcode-fixer - addtions welcome!

# Copyright (C) 2014
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License (version 3+) as
# published by the Free Software Foundation. You should have received
# a copy of the GNU General Public License along with this program.
# If not, see <http://www.gnu.org/licenses/>.

# Version info
date=201503130  # [year][month][date][extra]

# Locations
git_locate="https://raw.githubusercontent.com/Foggalong/hardcode-fixer/master"
local_icon="/home/${SUDO_USER:-$USER}/.local/share/icons/hicolor/48x48/apps/"

global_icon="/usr/share/icons/hicolor/48x48/apps/"
steam_icon="${global_icon}steam.png"

# global_apps="/usr/share/applications/"
global_apps_list="\
    /usr/share/applications/\
    /usr/share/applications/kde4/ \
    /usr/share/applications/data/ \
    /usr/share/app-install/desktop \
    /usr/local/share/applications/ \
    /usr/local/share/applications/kde4/ \
    /usr/share/applications/data \
    /usr/share/mimelnk/application \
    /home/${SUDO_USER:-$USER}/.local/share/applications/ \
    /home/${SUDO_USER:-$USER}/.local/share/applications/kde4/
"

# local_apps="/home/${SUDO_USER:-$USER}/.local/share/applications/ \
local_apps_list="\
    /home/${SUDO_USER:-$USER}/.local/share/applications/ \
    /home/${SUDO_USER:-$USER}/.local/share/applications/kde4
"

# Allows timeout when launched via 'Run in Terminal'
function gerror() { sleep 3; exit 1; }

function find_hardcoded_icons()
{
    hardcoded_csv_list="APPLICATION NAME, LAUNCHER, CURRENT ICON, NEW ICON"

    # Iterate over the list of launchers path
    for global_apps in $global_apps_list; do

		NOF_DESKTOP_FILES=$(ls -1 $global_apps/*.desktop | wc -l 2> /dev/null)
		echo -e "\n#> Found ${NOF_DESKTOP_FILES} .desktop files in '$global_apps'"

        # Go to the next applications path if current does not exist
        if [ ! -d "$global_apps" ]; then
            if [ "$verbose" == "1" ]; then
                echo -e "#> Path '$global_apps' doesn't exists"
            fi
            continue
        fi

        find $global_apps -iname '*.desktop' -exec grep -EH "[[:blank:]]*Icon[[:blank:]]*=[[:blank:]]*.*\..*" {} \; | grep -v ":\#Icon" > /tmp/tofix_apps.log
        # cat /tmp/tofix_apps.log

        # Itterating over lines of tofix.csv, each split into an array
        IFS=":"
        while read -r launcher icon; do
            name=$(grep -m 1 'Name' $launcher)
            name=$(echo $name | sed "s/Name.*=//") # <===== this should be improved some icons are localized: "Name=" or "Name[en]="
            icon=$(echo $icon | sed "s/Icon.*=//")
            echo -e "\t     Name: $name"
            echo -e "\t Launcher: $launcher"
            echo -e "\t     Icon: $icon"
            echo

            launcher=$(basename  "$launcher" | sed "s/\.desktop//" )
            hardcoded_csv_list="$hardcoded_csv_list\n$name, $launcher, $icon, "
        done < /tmp/tofix_apps.log
    done

    # For debug only
    echo
    echo
    echo -e "$hardcoded_csv_list" | column -t -s ,
    echo -e "$hardcoded_csv_list" > still_hardcoded.csv
    echo
}

# TODO: Iterate over parameters
# Deals with the flags
if [ -z "$1" ]; then
    mode="fix"
    dryrun="0"
else
    case $1 in
        -l|--local)
            mode="local";;
        -r|--revert)
            echo "This will undo all changes previously made."
            while true; do
                read -r -p "Are you sure you want to continue? " answer
                case $answer in
                    [Yy]* ) mode="revert"; break;;
                    [Nn]* ) exit;;
                    * ) echo "Please answer [Y/y]es or [N/n]o.";;
                esac
            done;;
        -h|--help)
            echo -e "\n" \
                "\nUSAGE: ./$(basename -- $0) [OPTION]\n" \
                "\rFixes hardcoded icons of installed applications.\n\n" \
                "\rCurrently supported options:\n" \
                "\r  -l, --local    \t Only fixes local launchers.\n" \
                "\r  -r, --revert   \t Reverts any changes made.\n" \
                "\r  -h, --help     \t Displays this help menu.\n" \
                "\r  -v, --version  \t Displays program version.\n" \
                "\r  -V, --verbose  \t Increase the verbosity.\n" \
                "\r  -d, --dryrun   \t Simulate the execution but makes nothing.\n" \
                "\r  -f, --find     \t Find remainning hardcoded icons.\n"
            exit 0 ;;
        -v|--version)
            echo -e "$(basename -- $0) $date\n"
            exit 0 ;;
        -V|--verbose)
            verbose="1" ;;
        -d|--dryrun)
            verbose="1"
            dryrun="1" ;;
        -f|--find)
            verbose="1"
            find_hardcoded_icons
            exit 0 ;;
        *)
            echo -e "$(basename -- $0): invalid option -- '$1'"
            echo -e "Try '$(basename -- $0) --help' for more information."
            gerror
    esac
fi

# Verifies if 'curl' is installed
if ! type "curl" >> /dev/null 2>&1; then
    echo -e \
        "$0: This script requires 'curl' to be installed\n" \
        "\rto fetch the required files and check for updates.\n" \
        "\rPlease install it and rerun this script."
    gerror
fi

# Checks for having internet access
if eval "curl -sk https://github.com/" >> /dev/null 2>&1; then
    : # pass
else
    echo -e \
        "No internet connection available. This script\n" \
        "\rrequires internet access to connect to GitHub\n" \
        "\rto check for updates and download 'to-fix' info."
    gerror
fi

# Check for newer version of fix.sh
new_date=$(curl -sk "${git_locate}"/fix.sh | grep "date=[0-9]\{9\}" | sed "s/[^0-9]//g")
if [ "$date" -lt "$new_date" ]; then
    echo -e \
        "You're running an out of date version of\n" \
        "\rthe script. Please download the latest\n" \
        "\rverison from the GitHub page or update\n" \
        "\rvia your package manager. If you continue\n" \
        "\rwithout updating you may run into problems."
    while true; do
        read -r -p "Would you like to [e]xit, or [c]ontinue?" answer
        case $answer in
            [Ee]* ) exit;;
            [Cc]* ) break;;
            * ) echo "Please answer [e]xit or [c]ontinue";;
        esac
    done
fi

# Downloads latest version of the list
curl -sk -o "/tmp/tofix.csv" "${git_locate}/tofix.csv"
sed -i -e "1d" "/tmp/tofix.csv" # crops header line
chown ${SUDO_USER:-$USER} "/tmp/tofix.csv"

# Checks for root
if [[ $UID -ne 0 ]] && [ $mode != "local" ]; then
    echo "The script must be run as root to (un)fix global launchers."
    while true; do
        read -r -p "Do you want to continue in local mode? " answer
        case $answer in
            [Yy]* )
                if [ "$mode" == "fix" ]; then
                    mode="local"; break
                elif [ "$mode" == "revert" ]; then
                    mode="l-revert"; break
                fi;;
            [Nn]* ) exit;;
            * ) echo "Please answer [Y/y]es or [N/n]o.";;
        esac
    done
fi

# Itterating over the list of dekstop applications paths
for global_apps in $(echo $global_apps_list); do

    # Go to the next applications path if current does not exist
    if [ ! -d "$global_apps" ]; then

        if [ "$verbose" == "1" ]; then
            echo -e "\n#> Path '$global_apps' doesn't exists"
        fi
        continue
    fi

	if [ "$verbose" == "1" ]; then
		NOF_DESKTOP_FILES=$(ls -1 $global_apps/*.desktop 2> /dev/null | wc -l)
		echo -e "\n#> Found ${NOF_DESKTOP_FILES} .desktop files in '$global_apps'"
		echo -e "#> Updating desktop icons in '$global_apps'"
	fi

    # Itterating over lines of tofix.csv, each split into an array
    IFS=","
    while read -r name launcher current new_icon; do

            # Basic corrections
            name=$(echo "$name" | sed -e "s/\r//g")
            launcher=$(echo "$launcher".desktop | sed -e "s/\r//g")
            current=$(eval echo "$current" | sed -e "s/\r//g")
            new_icon=$(eval echo "$new_icon" | sed -e "s/\r//g")
            # Escape non-standard and special characters in file names by creating a new variable
            old_icon="${current//\\/\\\\}" # escape backslashes
            # old_icon="${old_icon//\//\\/}" # escape slashes

            # Go to next line in CSV if launcher is missing
            if [ ! -f "$global_apps$launcher" ]; then
                continue
            else
                if [ "$verbose" == "1" ]; then
                    echo
                    echo -e "\t    Name: $name"
                    echo -e "\tLauncher: $global_apps$launcher"
                    echo -e "\t Current: $current"
                    echo -e "\t     New: $new_icon"
                    # echo -e "\tOld icon: $old_icon"
                fi
            fi

            # Fixing code
            if [ "$mode" == "fix" ] || [ "$mode" == "local" ]; then
                # Local & Steam launchers
                if [ -f "$local_apps$launcher" ]; then
                    if [ "$current" != "steam" ]; then
                        # Local launchers
                        if [ -f "$current" ]; then # checks if icon exists to copy
                            if grep -Gq "Icon[ \t]\+=[ \t]\+$current$" "$local_apps$launcher"; then
                                echo "L: Fixing $name..."
                                if [ ! -d "$local_icon" ]; then
                                    if [ "$dryrun" != "1" ]; then
                                        su -c "mkdir '$local_icon' -p" ${SUDO_USER:-$USER}
                                    fi
                                fi
                                if [ "$dryrun" != "1" ]; then
                                    cp "$current" "$local_icon$new_icon"
                                    sed -i "s/Icon[ \t]\+=[ \t]\+$old_icon.*/Icon=$new_icon/" "$local_apps$launcher"
                                fi
                            fi
                        fi
                    else
                        # Steam launchers
                        if [ -f "$steam_icon" ]; then # checks if steam icon exists to copy
                            if grep -Gq "Icon=$current$" "$local_apps$launcher"; then
                                echo "S: Fixing $name..."
                                if [ ! -d "$local_icon" ]; then
                                    if [ "$dryrun" != "1" ]; then
                                        su -c "mkdir '$local_icon' -p" ${SUDO_USER:-$USER}
                                    fi
                                fi
                                if [ "$dryrun" != "1" ]; then
                                    cp "$steam_icon" "$local_icon$new_icon.png"
                                    sed -i "s/Icon[ \t]\+=[ \t]\+steam.*/Icon=$new_icon/" "$local_apps$launcher"
                                fi
                            fi
                        fi
                    fi
                fi
                # Global launchers
                if [ $mode != "local" ] && [ -f "$global_apps$launcher" ]; then
                    if [ -f "$current" ]; then # checks if icon exists to copy
                        if grep -Gq "Icon=$current$" "$global_apps$launcher"; then
                            echo "G: Fixing $name..."
                            if [ "$dryrun" != "1" ]; then
                                cp "$current" "$global_icon$new_icon"
                                sed -i "s/Icon[ \t]\+=[ \t]\+.*/Icon=$new_icon/" "$global_apps$launcher"
                            fi
                        fi
                    fi
                fi
            # Reversion code
            elif [ "$mode" == "revert" ] || [ "$mode" == "l-revert" ]; then
                # Local revert
                if [ -f "$local_apps$launcher" ] && [ -f "$current" ]; then
                    if grep -Gq "Icon=$new_icon$" "$local_apps$launcher"; then
                        echo "F: Reverting $name..."
                        if [ "$dryrun" != "1" ]; then
                            rm -f "$local_icon$new_icon"*
                            sed -i "s/Icon[ \t]\+=[ \t]\+$new_icon.*/Icon=$old_icon/" "$local_apps$launcher"
                        fi
                    fi
                fi
                # Steam revert
                if [ -f "$local_apps$launcher" ] && [ -f "$steam_icon" ]; then
                    if grep -Gq "Icon=$new_icon$" "$local_apps$launcher"; then
                        echo "S: Reverting $name..."
                        if [ "$dryrun" != "1" ]; then
                            rm -f "$local_icon$new_icon"*
                            sed -i "s/Icon[ \t]\+=[ \t]\+$new_icon.*/Icon=$old_icon/" "$local_apps$launcher"
                        fi
                    fi
                fi
                # Global revert
                if [ $mode != "l-revert" ] && [ -f "$global_apps$launcher" ] && [ -f "$current" ]; then
                    if grep -Gq "Icon=$new_icon$" "$global_apps$launcher"; then
                        echo "G: Reverting $name..."
                        if [ "$dryrun" != "1" ]; then
                            rm -f "$global_icon$new_icon"*
                            sed -i "s/Icon[ \t]\+=[ \t]\+$new_icon.*/Icon=$old_icon/" "$global_apps$launcher"
                        fi
                    fi
                fi
            fi

    done < /tmp/tofix.csv

# Create an output log file with generated output
done | tee fix.log
