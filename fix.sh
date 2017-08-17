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
date=201708180  # [year][month][date][extra]

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
local_icon="$userhome/.local/share/icons/hicolor/48x48/apps/"
global_icon="/usr/share/icons/hicolor/48x48/apps/"
local_scalable_icon="$userhome/.local/share/icons/hicolor/scalable/apps/"
global_scalable_icon="/usr/share/icons/hicolor/scalable/apps/"
steam_icon="${global_icon}steam.png"


# Allows timeout when launched via 'Run in Terminal'
function gerror() { sleep 3; exit 1; }

# Backup icons
function backup() {
    current=$1
    new_icon=$2
    is_local=$3
    extension="${current##*.}"
    if [ -f "$current" ]; then # checks if icon exists to copy
        if [ "$extension" == "png" ] || [ "$extension" == "xpm" ];then
                if [ $is_local == "1" ]; then
                    if [ ! -f "$local_icon$new_icon" ] ;then
                        cp "$current" "$local_icon$new_icon"
                        chown -R  $username:$username "$local_icon$new_icon"
                    fi
                else
                    if [ ! -f "$global_icon$new_icon" ] ;then
                        cp "$current" "$global_icon$new_icon"
                    fi
                fi
        fi
        if [ "$extension" == "svg" ];then
            if [ $is_local == "1" ]; then
                if [ ! -f "$local_scalable_icon$new_icon" ] ;then
                    cp "$current" "$local_scalable_icon$new_icon"
                    chown -R  $username:$username "$local_scalable_icon$new_icon"
                fi
            else
                if [ ! -f "$global_scalable_icon$new_icon" ] ;then
                    cp "$current" "$global_scalable_icon$new_icon"
                fi
            fi
        fi
    fi
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
# Creates the missing folders
if [ ! -d "$local_scalable_icon" ]; then
    su -c "mkdir '$local_scalable_icon' -p" "$username"
fi
if [ ! -d "$local_icon" ]; then
    su -c "mkdir '$local_icon' -p" "$username"
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
chown "$username" "/tmp/tofix.csv"

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

# Itterating over lines of tofix.csv, each split into an array
IFS=","
while read -r name launcher current new_icon; do
    # Basic corrections
    name=$(echo "$name" | sed -e "s/\r//g")
    launcher=$(echo "$launcher".desktop | sed -e "s/\r//g")
    current=$(echo "$current" | sed -e "s/\r//g")
    new_icon=$(echo "$new_icon" | sed -e "s/\r//g")
    filename=$(basename "$current")
    extension="${filename##*.}"
    # Escape non-standard and special characters in file names by creating a new variable
    old_icon="${current//\\/\\\\}" # escape backslashes
    old_icon="${old_icon//\//\\/}" # escape slashes
    # Fixing code
    if [ "$current" == "hardcoded" ]; then #checks if the icon path is hardcoded
        if [ "$mode" == "local" ]; then
            combined_apps=("${local_apps[@]}")
        else
            combined_apps=("${local_apps[@]}" "${global_apps[@]}")
        fi

        for app_location in "${combined_apps[@]}"
        do  
            if [ -f "$new_current" ]; then
                break
            fi 
            if [ -f "$app_location$launcher" ]; then
                new_current=$(grep -Gq "Icon=*$" "$app_location$launcher")
            fi
        done
        if [ -f "$new_current" ];then
            sed -i "s/$name,$launcher,$current,$new_icon/$name,$launcher,$new_current,$new_icon/" "tofix.csv"
            sed -i "s/$name,$launcher,$current,$new_icon/$name,$launcher,$new_current,$new_icon/" "/tmp/tofix.csv"
        fi
    fi
    if [ ! -d "$local_scalable_icon" ]; then
        su -c "mkdir '$local_scalable_icon' -p" "$username"
    fi
    if [ ! -d "$local_icon" ]; then
        su -c "mkdir '$local_icon' -p" "$username}"
    fi
    if [ "$mode" == "fix" ] || [ "$mode" == "local" ]; then
        # Local & Steam launchers
        for local_app in "${local_apps[@]}"
        do
            if [ -f "$local_app$launcher" ]; then
                if [ "$current" != "steam" ]; then
                    if grep -Gq "Icon\s*=\s*$current$" "$local_app$launcher"; then
                        # Local launchers
                        echo "L: Fixing $name..."
                        backup $current $new_icon "1"
                        sed -i "s/Icon\s*=\s*${old_icon}.*/Icon=$new_icon/" "$local_app$launcher"
                    fi
                else
                    # Steam launchers
                    if [ -f "$steam_icon" ]; then # checks if steam icon exists to copy
                        if grep -Gq "Icon\s*=\s*$current$" "$local_app$launcher"; then
                            echo "S: Fixing $name..."
                            if [ ! -d "$local_icon" ]; then
                                su -c "mkdir '$local_icon' -p" "$username"
                            fi
                            if [ ! -f "$local_icon${new_icon}.png" ];then
                                cp "$steam_icon" "$local_icon${new_icon}.png"
                            fi
                            sed -i "s/Icon\s*=\s*steam.*/Icon=$new_icon/" "$local_app$launcher"
                        fi
                    fi
                fi
            fi
        done
        # Global launchers
        for global_app in "${global_apps[@]}"
        do
            if [ $mode != "local" ] && [ -f "$global_app$launcher" ]; then
                if grep -Gq "Icon\s*=\s*$current$" "$global_app$launcher"; then
                    echo "G: Fixing $name..."
                    backup $current $new_icon "0"
                    sed -i "s/Icon\s*=\s*${old_icon}.*/Icon=$new_icon/g" "$global_app$launcher"
                fi
            fi
        done
    # Reversion code
    elif [ "$mode" == "revert" ] || [ "$mode" == "l-revert" ]; then
        # Local revert
        for local_app in "${local_apps[@]}"
        do
            if [ -f "$local_app$launcher" ]; then
                if grep -Gq "Icon\s*=\s*$new_icon$" "$local_app$launcher"; then
                    echo "F: Reverting $name..."
                    rm -f "$local_icon$new_icon"*
                    rm -f "$local_scalable_icon$new_icon"*
                    sed -i "s/Icon=${new_icon}.*/Icon=$old_icon/" "$local_app$launcher"
                fi
            fi
            # Steam revert
            if [ -f "$local_app$launcher" ] && [ -f "$steam_icon" ]; then
                if grep -Gq "Icon\s*=\s*$new_icon$" "$local_app$launcher"; then
                    echo "S: Reverting $name..."
                    rm -f "$local_icon$new_icon"*
                    rm -f "$local_scalable_icon$new_icon"*
                    sed -i "s/Icon\s*=\s*${new_icon}.*/Icon=$old_icon/" "$local_app$launcher"
                fi
            fi
        done
        # Global revert
        for global_app in "${global_apps[@]}"
        do
            if [ $mode != "l-revert" ] && [ -f "$global_app$launcher" ]; then
                if grep -Gq "Icon\s*=\s*$new_icon$" "$global_app$launcher"; then
                    echo "G: Reverting $name..."
                    rm -f "$global_icon$new_icon"*
                    rm -f "$global_scalable_icon$new_icon"*
                    sed -i "s/Icon\s*=\s*${new_icon}.*/Icon=$old_icon/" "$global_app$launcher"
                fi
            fi
        done
    fi
done < "/tmp/tofix.csv"
