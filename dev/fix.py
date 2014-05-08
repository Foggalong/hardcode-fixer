#!/usr/bin/python3

# fix.py is written by Tom van der Lee (t0m.vd.l33@gmail.com) as a 
# rewrite of fix.sh. Written and maintained on GitHub at 
# https://github.com/Foggalong/hardcode-fixer - additions welcome!

# Copyright (C) 2014
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License (version 3+) as
# published by the Free Software Foundation. You should have received
# a copy of the GNU General Public License along with this program.
# If not, see <http://www.gnu.org/licenses/>.

from os import environ, execlpe, geteuid, listdir, remove
from os.path import expanduser, isfile
from sys import executable, argv
from urllib import request, error
from shutil import copy

#User variables
HOME = expanduser("~")
LOCAL = HOME + "/.local/share"
GLOBAL = "/usr/share"

#Version number
VERSION = "0.8.2-p"

#Help menu
HELP = """Usage: """ + argv[0] + """ [ACTION (MODE)]
Fixes hardcoded icons of installed applications.

If no [ACTION] or (MODE) is specified, this script
 will show this help menu. 
The default (MODE) is: all

Currently supported actions:
  -f, --fix		Fixes all hardcoded icons
  -r, --revert		Reverts all hardcoded icons
  -v, --version 	Displays script version
  -h, --help		Displays this help menu

Currently supported modes:
  all			Fixes/reverts both global and local hardcoded icons
  global		Fixes/reverts global hardcoded icons ONLY
  local			Fixes/reverts local hardcoded icons ONLY

NOTE: This script needs root rights to fix global hardcoded icons, but
 you don't need to run the script with sudo. The script will ask for sudo
 when it needs it."""

#Root message
ROOT_MESSAGE = """
Because most launchers are in /usr/share/applications/
fixing their hardcoded icon lines requites root privlages.\n"""

#Fix list
FIX_LIST = 'https://raw.githubusercontent.com/Foggalong/hardcode-fixer/master/data/list/tofix.txt'

#List with hardcoded icons
#item in list => [name, launcher, current, new]
hardcoded_list=[]

#Fetch the hardcoded iconlist from github
def fetchHardcoded():
	global hardcoded_list
	print("Fetching hardcoded list from GitHub")
	try:
		online_list = request.urlopen(FIX_LIST)
	except error.HTTPError as err:
		print("Oops.. cannot download list: " + FIX_LIST)
		print("HTTP Error " + str(err.code) + ": " + err.reason)
		exit()
	print("Decoding hardcoded list")
	decoded_list = online_list.read().decode('utf-8')
	for app in decoded_list.split('\n'):
		app = [item for item in app.split('|') if item != '']
		if app[0] == "end":
			break
		hardcoded_list.append(app)

#Aquire root rights
def aquireRoot():
	# Aquires root
	euid = geteuid()
	if euid != 0:
		print(ROOT_MESSAGE)
		print("Asking for root password...")
		args = ['sudo','-E', executable] + argv + [environ]
		execlpe('sudo', *args)
	print("\nAquired root!")

#Replaces certein pattern in launcher
def replace(launcher, pattern, replacement):
	file = open(launcher,'r')
	launcher_content = []
	for line in file:
		line = line.replace(pattern, replacement)
		launcher_content.append(line)
	file.close()
	file = open(launcher,'w')
	for line in launcher_content:
		file.write(line)
	file.close()
	
#Fix icons
def fix(directory):
	global hardcoded_list, HOME
	launcher_dir = directory + "/applications"
	icon_dir = directory + "/icons/hicolor/48x48/apps"
	for app in hardcoded_list:
		if len(app) == 4:
			name = app[0]
			launcher = app[1] + ".desktop"
			current_icon = app[2]
			new_icon = app[3]
			if launcher in listdir(launcher_dir) and not isfile(icon_dir + "/" + new_icon):
				print("Fixing: " + name + " - " +  launcher)
				if current_icon != "steam":
					copy(current_icon, icon_dir + "/" + new_icon)
				else:
					copy("/usr/share/icons/hicolor/48x48/apps/steam.png", icon_dir + "/" + new_icon)
				replace(launcher_dir + "/" + launcher, "Icon=" + current_icon, "Icon=" + new_icon)

#Unfix icons
def revert(directory):
	global hardcoded_list, HOME
	launcher_dir = directory + "/applications"
	icon_dir = directory + "/icons/hicolor/48x48/apps"
	for app in hardcoded_list:
		if len(app) == 4:
			name = app[0]
			launcher = app[1] + ".desktop"
			current_icon = app[2]
			new_icon = app[3]
			if launcher in listdir(launcher_dir) and isfile(icon_dir + "/" + new_icon):
				print("Reverting: " + name + " - " +  launcher)
				remove(icon_dir + "/" + new_icon)
				replace(launcher_dir + "/" + launcher, "Icon=" + new_icon, "Icon=" + current_icon)

#Handle arguments
if len(argv) == 3:
	action = argv[1]
	mode = argv[2]
elif len(argv) == 2:
	action = argv[1]
	mode = "all"
else:
	action = "-h"

#Process arguments
if action == "-f" or action == "--fix":
	if mode == "local":
		fetchHardcoded()
		fix(LOCAL)
	elif mode == "global":
		aquireRoot()
		fetchHardcoded()
		fix(GLOBAL)
	elif mode == "all":
		aquireRoot()
		fetchHardcoded()
		fix(LOCAL)
		fix(GLOBAL)
	else:
		print("Unknown mode: " + mode)
elif action == "-r" or action  == "--revert":
	if mode == "local":
		fetchHardcoded()
		revert(LOCAL)
	elif mode == "global":
		aquireRoot()
		fetchHardcoded()
		revert(GLOBAL)
	elif mode == "all":
		aquireRoot()
		fetchHardcoded()
		revert(LOCAL)
		revert(GLOBAL)
	else:
		print("Unknown mode: " + mode)
elif action == "-h" or action == "--help":
	print(HELP)
elif action == "-v" or action == "--version":
	print(argv[0] + " " + VERSION)
else:
	print(argv[0] + ": invalid action -- " + argv[1] +
		"\nTry '" + argv[0] + " --help' for more information.")
