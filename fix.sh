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

set -o errexit \
	-o noclobber \
	-o pipefail

unset GREP_OPTIONS  # avoid mess up

readonly SCRIPT_NAME="$(basename -- "$0")"
readonly SCRIPT_DIR="$(dirname -- "$0")"
readonly -a ARGS=( "$@" )

readonly PROGNAME="hardcode-fixer"
declare -i VERSION=201710170  # [year][month][date][extra]
# date=999999990  # deprecate the previous version

UPSTREAM_URL="https://raw.githubusercontent.com/Foggalong/hardcode-fixer/master"
LOCAL_APPS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
LOCAL_ICONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons"

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
declare -i FORCE_DOWNLOAD="${FORCE_DOWNLOAD:-0}"
declare -i VERBOSE="${VERBOSE:-0}"

msg() {
	printf "%s: %b\n" "$PROGNAME" "$*" >&2
}

verb() {
	[ "$VERBOSE" -eq 1 ] || return 0
	msg "INFO:" "$*"
}

warn() {
	msg "WARNING:" "$*"
}

err() {
	msg "ERROR:" "$*"
}

fatal() {
	err "$*"
	exit 1
}

_is_hardcoded() {
	# returns true if Icon contains a path
	local desktop_file="$1"
	LANG=C grep -q '^Icon=.*/.*' -- "$desktop_file"
}

_is_hardcoded_steam_app() {
	# returns true if it's a Steam launcher and Icon equals 'steam'
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

_is_update_available() {
	# returns true if the upstream version is greater than current
	local -i upstream_version

	upstream_version="$(get_upstream_version)"

	if [ "$VERSION" -lt "$upstream_version" ]; then
		return 0
	fi

	return 1
}

_has_marker() {
	# returns true if desktop file has a marker
	local desktop_file="$1"
	LANG=C grep -q '^X-Hardcode-Fixer-Marker=' -- "$desktop_file"
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
	local marker_value="$2"

	# add after Icon
	sed -i -e "/^Icon=/a \
	X-Hardcode-Fixer-Marker=${marker_value}
	" "$desktop_file"
}

icon_lookup() {
	# looks for icon in dirs in the list and returns absolute path to the icon
	local icon_name="$1"
	local icons_dir icon_path
	local -a icons_dirs=(
		"/usr/share/icons/hicolor/48x48/apps"
		"/usr/share/icons/hicolor"
		"/usr/share/pixmaps"
		"/usr/local/share/icons/hicolor/48x48/apps"
		"/usr/local/share/icons/hicolor"
		"/usr/local/share/pixmaps"
		"${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/48x48/apps"
		"${XDG_DATA_HOME:-$HOME/.local/share}/icons"
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
	# returns absolute path to the icon
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

get_upstream_version() {
	download_file "$UPSTREAM_URL/fix.sh" 2> /dev/null \
		| LANG=C grep -o 'date=[0-9]\+' \
		| head -1 \
		| tr -cd '[:digit:]'
}

get_from_db() {
	# returns icon name if found it
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

copy_icon_file() {
	local icon_path="$1"
	local icon_name="$2"
	local icon_ext="${icon_path##*.}"

	if [ ! -f "$icon_path" ]; then
		warn "Failed to copy '$icon_name' icon." \
			"File '$icon_path' does not exist."
		return 1
	fi

	mkdir -p "$LOCAL_ICONS_DIR"

	case "$icon_ext" in
		png|svg|svgz|xpm)
			cp -f "$icon_path" "$LOCAL_ICONS_DIR/${icon_name}.${icon_ext}"
			;;
		gif|ico|jpg|jpeg)
			if ! command -v convert > /dev/null 2>&1; then
				warn "imagemagick is not installed." \
					"Icon '${icon_name}.${icon_ext}' cannot be converted."
				return 1
			fi

			verb "Converting '${icon_name}.${icon_ext}' to" \
				"'${icon_name}.png' ..."
			convert "$icon_path" -alpha on -background none -thumbnail 48x48 \
				-flatten "$LOCAL_ICONS_DIR/${icon_name}.png"
			;;
		*)
			warn "'${icon_name}.${icon_ext}' has invalid icon format."
			return 1
	esac
}

download_file() {
	local url="$1"
	local file="${2:--}"  # it's not a typo, output to stdout by default

	if command -v wget > /dev/null 2>&1; then
		wget --no-check-certificate -q -O "$file" "$url" \
			|| fatal "Fail to download '$url' (wget exit code: $?)."
	elif command -v curl > /dev/null 2>&1; then
		curl -sk -o "$file" "$url" \
			|| fatal "Fail to download '$url' (curl exit code: $?)."
	else
		fatal "Fail to download '$url'.\n" \
			"\r This script requires 'wget' to be installed\n" \
			"\r to fetch the required files and check for updates.\n" \
			"\r Please install it and rerun this script."
	fi
}

translate_from_app_name() {
	# converts app name to icon name
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
	local dir_name base_name backup_file

	dir_name="$(dirname "$desktop_file")"
	base_name="$(basename "$desktop_file")"
	backup_file="${dir_name}/.${base_name}.orig"

	if [ -f "$backup_file" ]; then
		err "Backup file already exists."
		return 1
	fi

	cp "$desktop_file" "$backup_file"
}

restore_desktop_file() {
	local desktop_file="$1"
	local dir_name base_name backup_file

	dir_name="$(dirname "$desktop_file")"
	base_name="$(basename "$desktop_file")"
	backup_file="${dir_name}/.${base_name}.orig"

	if [ -f "$backup_file" ]; then
		mv -f "$backup_file" "$desktop_file"
	else
		err "Fail to find the backup file."
		return 1
	fi
}

fix_hardcoded_app() {
	local desktop_file="$1"
	local method="$2"
	local app_name icon_path new_icon_name desktop_file_name local_desktop_file

	app_name="$(get_app_name "$desktop_file")"
	icon_path="$(get_icon_path "$desktop_file")"
	new_icon_name="$(get_from_db "$desktop_file")"

	case "$method" in
		global)
			desktop_file_name="$(basename "$desktop_file")"
			local_desktop_file="$LOCAL_APPS_DIR/$desktop_file_name"

			if [ -e "$local_desktop_file" ]; then
				verb "'$app_name' already exists in local apps. Skipping."
				return 1
			fi

			mkdir -p "$(dirname "$local_desktop_file")"
			cp "$desktop_file" "$local_desktop_file"

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
			err "illegal method -- '$method'"
			return 1
	esac

	if [ -z "$new_icon_name" ]; then
		new_icon_name="$(translate_from_app_name "$desktop_file")"
	fi

	msg "Fixing '$app_name' [$method] ..."

	set_icon_name "$desktop_file" "$new_icon_name"
	set_marker_value "$desktop_file" "$method"
	copy_icon_file "$icon_path" "$new_icon_name"
}

apply() {
	local app_dir desktop_file

	if [ "$FORCE_DOWNLOAD" -eq 0 ] && [ -f "$SCRIPT_DIR/tofix.csv" ]; then
		DB_FILE="$SCRIPT_DIR/tofix.csv"
	else
		verb "Checking for update ..."
		if _is_update_available; then
			cat >&2 <<- EOF

			You're running an out of date version of the script.
			Please download the latest verison from the GitHub page
			or update via your package manager. If you continue
			without updating you may run into problems.

			Press [ENTER] to continue or Ctrl-c to exit
			EOF

			# Wait for user to read the message
			read -r < /dev/tty  # don't read from stdin
		fi

		DB_FILE="$(mktemp -u -t hardcode_db_XXXXX.csv)"

		msg "Downloading DB into '$DB_FILE' file ..."
		download_file "$UPSTREAM_URL/tofix.csv" "$DB_FILE"

		# delete CSV file when exiting
		cleanup() {
			verb "Removing '$DB_FILE' ..."
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
			fi
		done
	done

	msg "${FUNCNAME[0]}: Done!"
}

revert() {
	local app_dir app_name desktop_file icon_ext icon_name marker_value

	for app_dir in "${LOCAL_APPS_DIRS[@]}"; do
		for desktop_file in "$app_dir"/*.desktop; do
			[ -f "$desktop_file" ] || continue

			if _has_marker "$desktop_file"; then
				app_name="$(get_app_name "$desktop_file")"
				icon_name="$(get_icon_name "$desktop_file")"
				marker_value="$(get_marker_value "$desktop_file")"

				msg "Reverting '$app_name' ..."

				case "$marker_value" in
					global)
						rm -f -- "$desktop_file"
						;;
					local|steam)
						restore_desktop_file "$desktop_file" || continue
						;;
					*)
						err "invalid marker value -- '$marker_value'"
						continue
				esac

				for icon_ext in png svg svgz xpm; do
					if [ -f "$LOCAL_ICONS_DIR/$icon_name.$icon_ext" ]; then
						verb "Removing '$icon_name.$icon_ext' ..."
						rm -- "$LOCAL_ICONS_DIR/$icon_name.$icon_ext"
						break
					fi
				done
			fi
		done
	done

	msg "${FUNCNAME[0]}: Done!"
}

parse_opts() {
	local opt command
	local -a opts=()
	local -a commands=()

	usage() {
		local exit_code="$1"

		cat >&2 <<- EOF
		usage: $SCRIPT_NAME [command ...] [options]

		commands:
		 -A, --apply           fixes hardcoded icons of installed applications
		 -R, --revert          reverts any changes made
		 -V, --version         print $PROGNAME version and exit
		 -h, --help            show this help

		options:
		 -d, --force-download  download the new database (ignore the local DB)
		 -v, --verbose         be verbose

		Long commands without double '--' are also allowed.
		EOF

		exit "$exit_code"
	}

	# Translate --gnu-long-options and commands to -g (short options)
	for opt; do
		case "$opt" in
			--apply|apply)     opts+=( -A ) ;;
			--revert|revert)   opts+=( -R ) ;;
			--version|version) opts+=( -V ) ;;
			--force-download)  opts+=( -d ) ;;
			--help|help)       opts+=( -h ) ;;
			--verbose)         opts+=( -v ) ;;
			--[0-9a-Z]*)
				err "illegal option -- '$opt'"
				usage 128
				;;
			*) opts+=( "$opt" )
		esac
	done

	while getopts ":ARVdhv" opt "${opts[@]}"; do
		case "$opt" in
			A ) commands+=( "apply" )   ;;
			R ) commands+=( "revert" )  ;;
			V ) commands+=( "version" ) ;;
			d ) FORCE_DOWNLOAD=1        ;;
			h ) usage 0                 ;;
			v ) VERBOSE=1               ;;
			\?)
				err "illegal option -- '-$OPTARG'"
				usage 128
				;;
		esac
	done

	for command in "${commands[@]}"; do
		case "$command" in
			apply)  apply  ;;
			revert) revert ;;
			version)
				printf "%s (version %s)\n" "$PROGNAME" "$VERSION"
				if _is_update_available; then
					msg "update is available."
				fi
				exit 0
				;;
		esac
	done

	# display interactive menu, if no commands were passed
	if [ "${#commands[@]}" -eq 0 ]; then
		show_menu
	fi
}

show_menu() {
	local menu_item
	local -a menu_items=( "apply" "revert" "help" "quit" )
	local PS3="($PROGNAME)> "  # set custom prompt

	cat >&2 <<- EOF
	Welcome to $PROGNAME ($VERSION)!
	Type 'help' to view a list of commands or enter
	the number of the action you want to execute.

	EOF

	select menu_item in "${menu_items[@]}"; do
		case "${menu_item:-$REPLY}" in
			apply|[aA]*)  apply  ;;
			revert|[rR]*) revert ;;
			help|[hH]*)
				cat >&2 <<- EOF
				 apply     -  fixes hardcoded icons of installed applications
				 revert    -  reverts any changes made
				 help      -  displays this help menu
				 quit      -  quit $PROGNAME
				EOF
				;;
			quit|[qQeE]*) exit 0 ;;
			*) err "invalid command -- '$REPLY'"
		esac
	done < /dev/tty  # don't read from stdin
}

main() {
	if [ "$(id -u)" -eq 0 ]; then
		fatal "This script must be run as normal user."
	fi

	if [ "${#ARGS[@]}" -gt 0 ]; then
		parse_opts "${ARGS[@]}"
	else
		show_menu
	fi
}

main

exit 0
