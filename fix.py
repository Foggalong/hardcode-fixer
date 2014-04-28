#!/usr/bin/python3

from os import environ, execlpe, geteuid, listdir
from os.path import expanduser
from sys import executable, argv
from urllib.request import urlopen

#User variables
HOME = expanduser("~")
DATA_DIR = HOME + "/.local/share/data/hcf"
LOCAL = HOME + "/.local/share/applications"
GLOBAL = "/usr/share/applications"

#Version number
VERSION = "0.7"

#Help menu
HELP = """Usage: """ + argv[0] + """ [ACTION [MODE]]
Fixes hardcoded icons of installed applications.
If no [ACTION] or [MODE] is specified, this script
 will fix ALL hardcoded icons.

Currently supported actions:
  -f, --fix		Fixes all hardcoded icons
  -u, --unfix		Unfixes all hardcoded icons
  -v, --version 	Displays script version
  -h, --help		Displays this help menu

Currently supported modes:
  -l, --local	(Un)fix local hardcoded icons ONLY"""
	
#List with hardcoded icons
hardcoded_list=[]

#Fetch the hardcoded iconlist from github
def fetchHardcoded():
	global hardcoded_list
	online_list = urlopen('https://raw.githubusercontent.com/Foggalong/hardcode-fixer/master/data/tofix.txt')
	decoded_list = online_list.read().decode('utf-8')
	for app in decoded_list.split('\n'):
		app = [item for item in app.split('|') if item != '']
		if app[0] == "end":
			break
		hardcoded_list.append(app)

#Aquire root rights
def aquireRoot():
	warning_message = """
	Because most launchers are in /usr/share/applications/
	fixing their hardcoded icon lines requites root privlages.\n"""

	# Aquires root
	euid = geteuid()
	if euid != 0:
		print(warning_message)
		print("Asking for root password...")
		args = ['sudo', executable] + argv + [environ]
		execlpe('sudo', *args)
	print("\nAquired root!")

#Fix icons
def fix(directory):
	global LOCAL, GLOBAL
	
#Unfix icons
def unfix(directory):
	global LOCAL, GLOBAL

#Handle arguments
if len(argv) == 3:
	action = argv[1]
	mode = argv[2]
elif len(argv) == 2:
	action = argv[1]
	mode = "-a"
else:
	action = "-f"
	mode = "-a"

if action == "-f" or action == "--fix":
	fetchHardcoded()
	if mode == "-l" or mode == "--local":
		fix(LOCAL)
	elif mode == "-a":
		fix(LOCAL)
		fix(GLOBAL)
	else:
		print("Unknown mode: " + mode)
elif action == "-u" or action  == "--unfix":
	fetchHardcoded()
	if mode == "-l" or mode == "--local":
		unfix(LOCAL)
	elif mode == "-a":
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
