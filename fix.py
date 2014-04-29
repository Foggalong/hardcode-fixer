#!/usr/bin/python3

from os import environ, execlpe, geteuid, listdir, remove
from os.path import expanduser, isfile
from sys import executable, argv
from urllib.request import urlopen
from shutil import copy

#User variables
HOME = expanduser("~")
LOCAL = HOME + "/.local/share"
GLOBAL = "/usr/share"

#Version number
VERSION = "0.8"

#Help menu
HELP = """Usage: """ + argv[0] + """ [ACTION (MODE)]
Fixes hardcoded icons of installed applications.
If no [ACTION] or (MODE) is specified, this script
 will fix ALL hardcoded icons.

Currently supported actions:
  -f, --fix		Fixes all hardcoded icons
  -u, --unfix		Unfixes all hardcoded icons
  -v, --version 	Displays script version
  -h, --help		Displays this help menu

Currently supported modes:
  all				(Un)fix both global and local hardcoded icons
  local				(Un)fix local hardcoded icons ONLY"""

#Root message
ROOT_MESSAGE = """
Because most launchers are in /usr/share/applications/
fixing their hardcoded icon lines requites root privlages.\n"""

#List with hardcoded icons
#item in list => [name, launcher, current, new]
hardcoded_list=[]

#Fetch the hardcoded iconlist from github
def fetchHardcoded():
	global hardcoded_list
	print("Fetching hardcoded list from GitHub")
	online_list = urlopen('https://raw.githubusercontent.com/Foggalong/hardcode-fixer/master/data/tofix.txt')
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
			if launcher in listdir(launcher_dir):
				print("Fixing: " + name + " - " +  launcher)
				if current_icon != "steam":
					copy(current_icon, icon_dir + "/" + new_icon)
				else:
					copy("/usr/share/icons/hicolor/48x48/apps/steam.png", icon_dir + "/" + new_icon)
				replace(launcher_dir + "/" + launcher, "Icon=" + current_icon, "Icon=" + new_icon)

#Unfix icons
def unfix(directory):
	global hardcoded_list, HOME
	launcher_dir = directory + "/applications"
	icon_dir = directory + "/icons/hicolor/48x48/apps"
	for app in hardcoded_list:
		if len(app) == 4:
			name = app[0]
			launcher = app[1] + ".desktop"
			current_icon = app[2]
			new_icon = app[3]
			if launcher in listdir(launcher_dir):
				print("Unfixing: " + name + " - " +  launcher)
				if isfile(icon_dir + "/" + new_icon):
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
	action = "-f"
	mode = "all"

#Process arguments
if action == "-f" or action == "--fix":
	if mode == "local":
		fetchHardcoded()
		fix(LOCAL)
	elif mode == "all":
		aquireRoot()
		fetchHardcoded()
		fix(LOCAL)
		fix(GLOBAL)
	else:
		print("Unknown mode: " + mode)
elif action == "-u" or action  == "--unfix":
	if mode == "local":
		fetchHardcoded()
		unfix(LOCAL)
	elif mode == "all":
		aquireRoot()
		fetchHardcoded()
		unfix(LOCAL)
		unfix(GLOBAL)
	else:
		print("Unknown mode: " + mode)
elif action == "-h" or action == "--help":
	print(HELP)
elif action == "-v" or action == "--version":
	print(argv[0] + " " + VERSION)
else:
	print(argv[0] + ": invalid action -- " + argv[1] +
		"\nTry '" + argv[0] + " --help' for more information.")
