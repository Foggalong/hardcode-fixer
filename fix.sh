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
app_dirs=("$userhome/.local/share/applications/"
          "$userhome/.local/share/applications/kde4/"
          "$(sudo -u $username xdg-user-dir DESKTOP)/"
          "/usr/share/applications/"
          "/usr/share/applications/kde4/"
          "/usr/local/share/applications/"
          "/usr/local/share/applications/kde4/")
local_apps="$userhome/.local/share/applications/"
local_icon="$userhome/.local/share/icons/hicolor/48x48/apps/"
steam_icon="/usr/share/icons/hicolor/48x48/apps/steam.png"

# Allows timeout when launched via 'Run in Terminal'
function gerror() { sleep 3; exit 1; }


# Fix Launcher
function fix_launch() {
    launcher=$1
    name=$2
    icon=$3
    type=$4

    # Check if already fixed, if not create marked launcher copy
    local_version="$local_apps$name.desktop"
    if [ -f "$local_version" ]; then
        line=$(head -n 1 $local_version)
        if [[ $line == "# HC"* ]]; then
            return
        else
            cp "$local_version" "$local_version.old"
            sed -i '1i# HC:Local' "$local_version"
        fi
    else
        cp "$launcher" "$local_version"
        sed -i '1i# HC:Global' "$local_version"
    fi

    echo -n "$type: Fixing $name..."

    # Making copy of needed icon and determining new icon name
    if [[ $type == "H" ]]; then
        new_icon=$(echo ${name} | sed -e 's/\ /_/' ) # | sed -e 's/\./_/' )
        ext=$(echo ${icon} | sed -e 's/.*\.//' )
        cp $icon $local_icon$new_icon.$ext
    elif [[ $type == "S" ]]; then
        exec=$(grep '^Exec=' ${file} | sed -e 's/.*Exec=//' )
        new_icon=steam_icon_$(echo $exec | sed -e 's/steam\ steam:\/\/rungameid\/*//' )
        cp $steam_icon "$local_icon$new_icon.png"
    fi

    sed -i "s|Icon=${icon}.*|Icon=${new_icon}|g" $local_version
    echo " done"
}

# Deals with the flags
if [ -z "$1" ]; then
    mode="fix"
else
    case $1 in
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

if [ "$mode" == "fix" ]; then
    # Iterate over all the launcher locations
    for location in ${app_dirs[@]}; do
        # Iterate over the files in those locations
        for file in ${location}*; do
            # Check if the file is a launcher
            if [[ ${file} == *.desktop ]]; then
                name=$(echo ${file} | sed -e 's/.*\///' | sed -e 's/\.desktop//' )
                icon=$(grep '^Icon=' ${file} | sed -e 's/.*Icon=//' )
                # Check for signs of hardcoding
                if [[ $icon == *"/"* ]]; then
                    # What to do if the icon line is standard hardcoded
                    fix_launch ${file} ${name} ${icon} "H"
                elif [[ $icon == "steam" ]] && [[ ${name} != "steam" ]]; then
                    # What to do if it's using the generic Steam icon
                    fix_launch ${file} ${name} ${icon} "S"
                # elif [[ $icon = *"."* ]]; then
                #     # What to do if it's extension hardcoded
                #     fix_launch ${file} ${name} ${icon} "E"
                fi
            fi
        done
    done
elif [ "$mode" == "revert" ]; then
    for file in ${local_apps}*; do
        if [[ ${file} == *.desktop ]]; then
            # Check if launcher is product of hc-fix
            line=$(head -n 1 $file)
            if [[ $line == "# HC:Local" ]]; then
                echo Local revert on $file
                # TODO add in the reversion code
            elif [[ $line == "# HC:Global" ]]; then
                echo Global revert on $file
                # TODO add in the reversion code
            fi
        fi
    done
fi
