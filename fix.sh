#!/usr/bin/env bash

# Script for fixing hardcoded icons. Written and maintained on GitHub
# at https://github.com/Foggalong/hardcode-fixer - addtions welcome!

# Copyright (C) 2014
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License (version 3+) as
# published by the Free Software Foundation. You should have received
# a copy of the GNU General Public License along with this program.
# If not, see <http://www.gnu.org/licenses/>.

if test -z "$BASH_VERSION"; then
	printf "Error: this script only works in bash.\n" >&2
	exit 1
fi

# set -x  # Uncomment to debug this shell script
set -o errexit \
	-o noclobber \
	-o pipefail

unset GREP_OPTIONS  # avoid mess up

readonly SCRIPT_NAME="$(basename -- "$0")"
readonly SCRIPT_DIR="$(dirname -- "$0")"
readonly -a ARGS=("$@")

readonly PROGNAME="hardcode-fixer"
declare -i VERSION=201710140  # [year][month][date][extra]
# date=999999990  # deprecate the previous version

message() {
	printf "%s: %b\n" "$PROGNAME" "$*" >&2
}

verbose() {
	[ "$VERBOSE" = 1 ] || return 0
	message "INFO:" "$@"
}

warning() {
	message "WARN:" "$@"
}

fail() {
	message "ERR:" "$@"
	exit 1
}

_is_hardcoded() {
	local desktop_file="$1"
	LANG=C grep -q '^Icon=.*/.*' -- "$desktop_file"
}

_is_hardcoded_steam_app() {
	local desktop_file="$1"
	local icon_name

	if LANG=C grep -q 'steam://run' -- "$desktop_file"; then
		icon_name="$(get_icon_name "$desktop_file")"
		if [ "$icon_name" = "steam" ]; then
			return 0
		fi
	fi

	return 1
}

get_app_name() {
	local desktop_file="$1"
	awk -F= '/^Name/ { print $2; exit }' "$desktop_file"
}

get_icon_name() {
	local desktop_file="$1"
	awk -F= '/^Icon/ { print $2; exit }' "$desktop_file"
}

get_steam_app_id() {
	# returns id of the Steam app
	local desktop_file="$1"
	sed -n '/^Exec/ s/.*\/\([0-9]\+\)/\1/p' "$desktop_file"
}

get_steam_icon_name() {
	# returns name of the Steam icon (steam_icon_ID)
	local desktop_file="$1"
	printf 'steam_icon_%s' "$(get_steam_app_id "$desktop_file")"
}

set_icon_name() {
	# changes an icon for the desktop entry
	local desktop_file="$1"
	local icon_name="$2"

	sed -i -e "/^Icon=/c \
	Icon=${icon_name}
	" "$desktop_file"
}

get_marker_value() {
	local desktop_file="$1"
	awk -F= '/^X-Hardcode-Fixer-Marker/ { print $2; exit }' "$desktop_file"
}

set_marker_value() {
	local desktop_file="$1"
	local marker_value="${2:-local}"

	# append after Icon
	sed -i -e "/^Icon=/a \
	X-Hardcode-Fixer-Marker=${marker_value}
	" "$desktop_file"
}

icon_lookup() {
	# returns path to an icon (icon lookup for poor man)
	local icon_name="$1"
	local -a icons_dirs=(
		"/usr/share/icons/hicolor/48x48/apps"
		"/usr/share/icons/hicolor"
		"/usr/local/share/icons/hicolor/48x48/apps"
		"/usr/local/share/icons/hicolor"
		"${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/48x48/apps"
		"${XDG_DATA_HOME:-$HOME/.local/share}/icons"
		"/usr/share/pixmaps"
		"/usr/local/share/pixmaps"
	)

	for icons_dir in "${icons_dirs[@]}"; do
		for icon_path in "$icons_dir/$icon_name".*; do
			[ -f "$icon_path" ] || continue
			printf '%s' "$icon_path"
			return 0  # only the first match
		done
	done
}

get_icon_path() {
	local desktop_file="$1"
	local icon_value icon_path

	icon_value="$(get_icon_name "$desktop_file")"

	if [ "${icon_value:0:1}" = "/" ]; then
		# it's absolute path
		icon_path="$icon_value"
	else
		icon_path="$(icon_lookup "$icon_value")"
	fi

	printf '%s' "$icon_path"
}

copy_icon_file() {
	local icon_path="$1"
	local icon_name="$2"
	local icon_ext="${icon_path##*.}"

	if [ -f "$icon_path" ]; then
		mkdir -p "$LOCAL_ICONS_DIR"
		cp -f "$icon_path" "$LOCAL_ICONS_DIR/${icon_name}.${icon_ext}"
	else
		warning "Cannot find an icon for '$icon_name'."
		return 1
	fi
}

download_file() {
	local url="$1"
	local file="${2:--}"  # is not a typo, output to stdout by default

	verbose "Downloading '$url' ..."

	if command -v wget > /dev/null 2>&1; then
		wget --no-check-certificate -q -O "$file" "$url" \
			|| fail "Fail to download '$url'."
	elif command -v curl > /dev/null 2>&1; then
		curl -sk -o "$file" "$url" \
			|| fail "Fail to download '$url'."
	else
		fail "\n" \
		"\r This script requires 'wget' to be installed\n" \
		"\r to fetch the required files and check for updates.\n" \
		"\r Please install it and rerun this script."
	fi
}

get_from_db() {
	# returns icon name if find it
	local desktop_file="$1"
	local app_name

	app_name="$(get_app_name "$desktop_file")"

	awk -F, -v app_name="$app_name" '
	BEGIN { IGNORECASE = 1; }
	$1 == app_name {
		print $4
		exit
	}
	' "$DB_FILE"
}

translate_from_app_name() {
	local desktop_file="$1"

	# 1. remove text between parentheses
	# 2. replace spaces with hyphens
	# 3. replace two or more hyphens by one
	# 4. to lowercase
	# 5. delete invalid characters
	get_app_name "$desktop_file" \
		| sed \
			-e 's/[ ]([^)]\+)//g' \
			-e 's/[ ]/-/g' \
			-e 's/-\+/-/g' \
		| tr '[:upper:]' '[:lower:]' \
		| tr -cd '[:alnum:]-_'
}

backup_desktop_file() {
	local desktop_file="$1"
	local dir_name base_name new_file_path

	dir_name="$(dirname "$desktop_file")"
	base_name="$(basename "$desktop_file")"
	new_file_path="${dir_name}/.${base_name}.orig"

	if [ -f "$new_file_path" ]; then
		versbose "Backup file already exists"
		return 1
	fi

	cp -a "$desktop_file" "$new_file_path"
}

restore_desktop_file() {
	local desktop_file="$1"
	local dir_name base_name file_path

	dir_name="$(dirname "$desktop_file")"
	base_name="$(basename "$desktop_file")"
	file_path="${dir_name}/.${base_name}.orig"

	[ -f "$file_path" ] || return 1
	mv -f "$file_path" "$desktop_file"
}

fix_hardcoded_app() {
	local desktop_file="$1"
	local method="$2"
	local app_name icon_path new_icon_name local_desktop_file

	app_name="$(get_app_name "$desktop_file")"
	icon_path="$(get_icon_path "$desktop_file")"
	new_icon_name="$(get_from_db "$desktop_file")"

	case "$method" in
		global)
			local_desktop_file="$LOCAL_APPS_DIR/$(basename "$desktop_file")"

			if [ -e "$local_desktop_file" ]; then
				verbose "'$app_name' already exists in local apps. Skipping."
				return 1
			fi

			mkdir -p "$(dirname "$local_desktop_file")"
			cp -a "$desktop_file" "$local_desktop_file"

			desktop_file="$local_desktop_file"
			;;
		local)
			backup_desktop_file "$desktop_file"
			;;
		steam)
			backup_desktop_file "$desktop_file"
			new_icon_name="$(get_steam_icon_name "$desktop_file")"
			;;
		*)
			warning "illegal method -- $method"
			return 1
	esac

	if [ -z "$new_icon_name" ]; then
		new_icon_name="$(translate_from_app_name "$desktop_file")"
	fi

	message "Fixing '$app_name' [$method] ..."

	set_icon_name "$desktop_file" "$new_icon_name"
	set_marker_value "$desktop_file" "$method"
	copy_icon_file "$icon_path" "$new_icon_name"
}

apply() {
	local app_dir file

	if [ "$FORCE_DOWNLOAD" = 0 ] && [ -f "$SCRIPT_DIR/tofix.csv" ]; then
		DB_FILE="$SCRIPT_DIR/tofix.csv"
	else
		DB_FILE="$(mktemp -u -t hardcode_db_XXXXX.csv)"

		message "Downloading DB into '$DB_FILE' file ..."
		download_file "$DB_URL" "$DB_FILE"

		# remove csv file when exit
		cleanup() {
			verbose "Removing '$DB_FILE' ..."
			rm -f "$DB_FILE"
			unset DB_FILE
		}

		trap cleanup EXIT HUP INT TERM
	fi

	for app_dir in "${GLOBAL_APPS_DIRS[@]}"; do
		for desktop_file in "$app_dir"/*.desktop; do
			[ -f "$desktop_file" ] || continue
			if _is_hardcoded "$desktop_file"; then
				fix_hardcoded_app "$desktop_file" "global" || continue
				continue
			fi
		done
	done

	for app_dir in "${LOCAL_APPS_DIRS[@]}"; do
		for desktop_file in "$app_dir"/*.desktop; do
			[ -f "$desktop_file" ] || continue
			if _is_hardcoded "$desktop_file"; then
				fix_hardcoded_app "$desktop_file" "local" || continue
			elif _is_hardcoded_steam_app "$desktop_file"; then
				fix_hardcoded_app "$desktop_file" "steam" || continue
			else
				continue
			fi
		done
	done
}

revert() {
	local app_name app_dir file marker_value

	for app_dir in "${LOCAL_APPS_DIRS[@]}"; do
		for desktop_file in "$app_dir"/*.desktop; do
			[ -f "$desktop_file" ] || continue

			app_name="$(get_app_name "$desktop_file")"
			icon_name="$(get_icon_name "$desktop_file")"
			marker_value="$(get_marker_value "$desktop_file")"

			if [ -n "$marker_value" ]; then
				message "Reverting '$app_name' ..."

				case "$marker_value" in
					global)
						rm -f -- "$desktop_file"
						;;
					local|steam)
						restore_desktop_file "$desktop_file"
						;;
				esac

				verbose "Removing '$icon_name' icon ..."
				for ext in png svg xpm; do
					[ -f "$LOCAL_ICONS_DIR/$icon_name.$ext" ] || continue
					rm -- "$LOCAL_ICONS_DIR/$icon_name.$ext"
					break
				done
			fi
		done
	done
}

cmdline() {
	local arg action

	show_usage() {
		cat >&2 <<- EOF
		usage:
		 $SCRIPT_NAME {-a --apply}  [options]
		 $SCRIPT_NAME {-r --revert} [options]

		ACTIONS:
		 -a, --apply          fixes hardcoded icons of installed applications
		 -r, --revert         reverts any changes made

		OPTIONS:
		 -d --force-download  download the new database (ignore the local DB)
		 -V --version         print $PROGNAME version and exit
		 -v --verbose         be verbose
		 -h --help            show this help
		EOF
	}

	for arg in "${ARGS[@]}"; do
		case "$arg" in
			-a|--apply)
				action="apply"
				;;
			-r|--revert)
				action="revert"
				;;
			-d|--force-download)
				FORCE_DOWNLOAD=1
				;;
			-v|--verbose)
				VERBOSE=1
				;;
			-V|--version)
				printf "%s (version: %s)\n" "$PROGNAME" "$VERSION"
				exit 0
				;;
			-h|--help)
				show_usage
				exit 0
				;;
			*)
				message "illegal option -- '$arg'"
				show_usage
				exit 2
				;;
		esac
	done

	case "$action" in
		apply)
			apply
			;;
		revert)
			revert
			;;
		*)
			fail "You must choose an action.\n" \
				"\rType '$SCRIPT_NAME --help' to display help."
			;;
	esac

	message "Done!"
}

show_menu() {
	local -a menu_items=( "apply" "revert" "verbose" "help" "quit" )
	local num_items="${#menu_items[@]}"
	local PS3="[1-${num_items}]> "  # set custom prompt
	local COLUMNS=1  # force listing to be vertical

	cat >&2 <<- EOF
	Welcome to $PROGNAME ($VERSION)!
	Type 'help' to view a list of commands or enter
	the number of the action you want to execute.

	EOF

	select menu_item in "${menu_items[@]}"; do
		case "${menu_item:-$REPLY}" in
			apply|[aA]*)
				apply
				break
				;;
			revert|[rR]*)
				revert
				break
				;;
			verbose|verb*)
				VERBOSE=1
				message "Verbose mode is enabled."
				;;
			help|[hH]*)
				cat >&2 <<- EOF

				 apply     —  Fixes hardcoded icons of installed applications
				 revert    —  Reverts any changes made
				 verbose   -  Be verbose
				 help      —  Displays this help menu
				 quit      -  Quit "$PROGNAME"

				EOF
				;;
			quit|[qQ]*)
				exit 0
				;;
			*)
				echo "$REPLY -- invalid command"
				;;
		esac
	done < /dev/tty  # don't read from stdin

	message "Done!"

	# Allows pause when launched via 'Run in Terminal'
	read -r -p 'Press [Enter] to close' < /dev/tty  # don't read from stdin
}

main() {
	if [ "$(id -u)" -eq 0 ]; then
		fail "This script must be run as normal user."
	fi

	declare DB_URL="https://raw.githubusercontent.com/Foggalong/hardcode-fixer/master/tofix.csv"
	declare LOCAL_APPS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
	declare LOCAL_ICONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons"

	declare -a GLOBAL_APPS_DIRS=(
		"/usr/share/applications"
		"/usr/share/applications/kde4"
		"/usr/local/share/applications"
		"/usr/local/share/applications/kde4"
	)

	declare -a LOCAL_APPS_DIRS=(
		"${XDG_DATA_HOME:-$HOME/.local/share}/applications"
		"${XDG_DATA_HOME:-$HOME/.local/share}/applications/kde4"
		"$(xdg-user-dir DESKTOP)"
	)

	# default values of options
	declare -i FORCE_DOWNLOAD=0
	declare -i VERBOSE=0

	if [ "${#ARGS[@]}" -gt 0 ]; then
		cmdline
	else
		show_menu
	fi
}

main

exit 0
