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
date=201709040  # [year][month][date][extra]

# Locations
git_locate="https://raw.githubusercontent.com/Foggalong/hardcode-fixer/master"
username=${SUDO_USER:-$USER}
userhome="/home/$username"
global_apps=("/usr/share/applications/"
            "/usr/share/applications/kde4/"
            "/usr/local/share/applications/"
            "/usr/local/share/applications/kde4/")
local_apps=("$userhome/.local/share/applications/"
            "$userhome/.local/share/applications/kde4/"
            "$(sudo -u $username xdg-user-dir DESKTOP)/")


# Allows timeout when launched via 'Run in Terminal'
function gerror() { sleep 3; exit 1; }


# Fix Launcher
function fix_launch() {
    launcher=$1
    icon=$2
    type=$3
    name=$(echo ${launcher} | sed -e 's/.*\///' | sed -e 's/\.desktop//' )

    echo "$type: Fixing $name..."
    if [[ $type == "L" ]] || [[ $type == "G" ]]; then
        new_icon=$(echo ${name} | sed -e 's/\ /_/' | sed -e 's/\./_/' )
        echo "    From $icon to $new_icon" # debug code
    elif [[ $type == "S" ]]; then
        exec=$(grep '^Exec=' ${file} | sed -e 's/.*Exec=//' )
        new_icon=steam_icon_$(echo $exec | sed -e 's/steam\ steam:\/\/rungameid\/*//' )
        echo "    From $icon to $new_icon" # debug code
    fi
    # TODO make this code functional
    # if [[ $type == "L" ]] || [[ $type == "S" ]]; then
    #     cp $launcher "${launcher}.old"
    #     # make edit to icon line of original launcher
    # elif [[ $type == "G" ]]
    #     cp $launcher "$userhome/.local/share/applications/"
    #     # make edit to icon line of local copy of global launcher
    # fi
}

# Deals with the flags
if [ -z "$1" ]; then
    mode="fix"
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
            echo -e \
                "Usage: ./$(basename -- $0) [OPTION]\n" \
                "\rFixes hardcoded icons of installed applications.\n\n" \
                "\rCurrently supported options:\n" \
                "\r  -l, --local \t Only fixes local launchers.\n" \
                "\r  -r, --revert \t Reverts any changes made.\n" \
                "\r  -h, --help \t\t Displays this help menu.\n" \
                "\r  -v, --version \t Displays program version.\n"
            exit 0 ;;
        -v|--version)
            echo -e "$(basename -- $0) $date\n"
            exit 0 ;;
        *)
            echo -e "$(basename -- $0): invalid option -- '$1'"
            echo -e "Try '$(basename -- $0) --help' for more information."
            gerror
    esac
fi


# TODO this entire 40+ LOC is just for checking for updates. should this still be here?
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


# Checks for root
# TODO assess whether this code is actually needed anymore. It would seem to me that under the new system
# TODO of fixing the difference between local and global is in method, not in privilage required
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


if [ "$mode" == "local" ] || [ "$mode" == "fix" ]; then
    if [ "$mode" == "fix" ]; then
        # Iterate over all the global launcher locations
        for location in ${global_apps[@]}; do
            # Iterate over the files in those locations
            for file in ${location}*; do
                # Check if the file is a launcher
                if [[ ${file} == *.desktop ]]; then
                    icon=$(grep '^Icon=' ${file} | sed -e 's/.*Icon=//' )
                    # Check for signs of hardcoding
                    if [[ $icon == *"/"* ]] || [[ $icon = *"."* ]]; then
                        # What to do if the icon line is standard hardcoded
                        fix_launch ${file} ${icon} "G"
                    fi
                fi
            done
        done
    fi
    # Iterate over all the local launcher locations
    for location in ${local_apps[@]}; do
        # Iterate over the files in those locations
        for file in ${location}*; do
            # Check if the file is a launcher
            if [[ ${file} == *.desktop ]]; then
                icon=$(grep '^Icon=' ${file} | sed -e 's/.*Icon=//' )
                # Check for signs of hardcoding
                if [[ $icon == *"/"* ]] || [[ $icon = *"."* ]]; then
                    # What to do if the icon line is standard hardcoded
                    fix_launch ${file} ${icon} "L"
                elif [[ $icon == "steam" ]] && [[ ${name} != "steam" ]]; then
                    # What to do if it's using the generic Steam icon
                    fix_launch ${file} ${icon} "S"
                fi
            fi
        done
    done
elif [ "$mode" == "revert" ] || [ "$mode" == "l-revert" ]; then
    # TODO add in the reversion code
    sleep 0
fi
