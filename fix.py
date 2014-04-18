#!/usr/bin/python3

# Base script for the safe hardcoded icon fixer.
# Copyright (C) 2014  Joshua Fogg

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License (version 3+) as 
# published by the Free Software Foundation. You should have received
# a copy of the GNU General Public License along with this program.  
# If not, see <http://www.gnu.org/licenses/>.

from os import environ, execlpe, geteuid, listdir
from os.path import expanduser
from sys import executable, argv

# Gets argument
# -f for fix, -u for unfix
script, mode = argv

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

# List of known apps that use hardcoded icons
hardcoded = [
	# .desktop name needed ["Android Studio", "/opt/android-studio/bin/idea.png", " androidstudio"]
	# .desktop name needed ["Aptik", "/usr/share/pixmaps/aptik.png", "aptik"]
	# .desktop name needed ["Arista", "/usr/share/arista/ui/icon.svg", "arista"]
	["Bastion.desktop", "steam", "steam_icon_107100"],
	# .desktop name needed ["Conky Manager", " /usr/share/pixmaps/conky-manager.png", " conky-manager"]
	# .desktop name needed ["Dogecoin-qt (AUR)", "/usr/share/pixmaps/dogecoin.png", "dogecoin"]
	["Dota 2.desktop", "steam", "steam_icon_570"],
	# .desktop name needed ["Driver Manager", "/usr/share/icons/hicolor/scalable/apps/driver-manager.svg", "jockey"]
	# .desktop name needed ["Easy Life", "/usr/share/pixmaps/easylife.png", "easylife"]
	# .desktop name needed ["Fade In", "/usr/share/fadein/icon_app/fadein_icon_128x128.png", "fadein"]
	["formatjunkie.desktop", "/opt/extras.ubuntu.com/formatjunkie/pixmap/fjt.png", "fjt"],
	# .desktop name needed ["Gcolor2", " /usr/share/pixmaps/gcolor2/gcolor2.xpm", "gcolor2"]
	["gespeaker.desktop", "/usr/share/gespeaker/data/icons/gespeaker.svg", "gespeaker"],
	# .desktop name needed ["GNOME Weather", "org.gnome.Weather.Application", "gnome-weather"]
	["guvcview.desktop", "/usr/share/pixmaps/guvcview/guvcview.png", "guvcview"],
	["www.octave.org-octave.desktop", "/usr/share/octave/3.6.4/imagelib/octave-logo.svg", "octave"],
	# .desktop name needed ["Graphic Network Simulator", "/usr/share/pixmaps/gns3.xpm", "gns"]
	["grisbi", "/usr/share/pixmaps/grisbi/grisbi.svg", "grisbi"],
	# .desktop name needed ["HipChat", "hipchat.png", "hipchat"]
	# .desktop name needed ["Intel Graphics Installer", "/usr/share/intel-linux-graphics-installer/images/logo.png", "intel-installer"]
	# .desktop name needed ["IntelliJ IDEA", "/opt/idea-IC/bin/idea.png", "idea"]
	["Kerbal Space Program.desktop", "steam", "steam_icon_220200"],
	["Left 4 Dead 2.desktop", "steam", "steam_icon_550"],
	["Left 4 Dead 2 Beta.desktop", "steam", "steam_icon_223530"],
	# .desktop name needed ["Lightworks", "/usr/share/lightworks/Icons/App.png", "lightworks"]
	# .desktop name needed ["Lucky Backup", "/usr/share/pixmaps/luckybackup.png", "luckybackup"]
	# .desktop name needed ["Master PDF Editor", "/opt/master-pdf-editor/master-pdf-editor.png", "master-pdf-editor"]
	# .desktop name needed ["My Weather Indicator", "/opt/extras.ubuntu.com/my-weather-indicator/share/pixmaps/my-weather-indicator.png", "indicator-weather"]
	["netbeans.desktop", "/usr/share/netbeans/7.0.1/nb/netbeans.png", "netbeans"],
	# .desktop name needed ["Ninja IDE", "/usr/share/ninja-ide/img/icon.png", "ninja-ide"]
	# .desktop name needed ["Nitro", "/usr/share/nitrotasks/media/nitrotasks.png", "nitrotasks"]
	# .desktop name needed ["OmegaT", "/usr/share/omegat/images/OmegaT.xpm", "omegat"]
	# .desktop name needed ["Oracle SQL Developer", "/opt/oracle-sqldeveloper/icon.png", "N/A"]
	# .desktop name needed ["PacmanXG", "/usr/share/pixmaps/pacmanxg.png", "pacmanxg"]
	# .desktop name needed ["Pamac (Install)", "/usr/share/pamac/icons/32x32/apps/pamac.png", "system-software-install"]
	# .desktop name needed ["Pamac (Update)", "/usr/share/pamac/icons/32x32/apps/pamac.png", "system-software-update"]
	# .desktop name needed ["PHP Storm", "PhpStorm-133.803/bin/webide.png", "phpstorm"]
	# .desktop name needed ["Pycharm", "/home/radio/Descargas/pycharm-community-3.1.1/bin/pycharm.png", "pycharm"]
	["python2.6.desktop", "/usr/share/pixmaps/python2.6.xpm", "python2.6"],
	["python2.7.desktop", "/usr/share/pixmaps/python2.7.xpm", "python2.7"],
	["python3.0.desktop", "/usr/share/pixmaps/python3.0.xpm", "python3.0"],
	["python3.1.desktop", "/usr/share/pixmaps/python3.1.xpm", "python3.1"],
	["python3.2.desktop", "/usr/share/pixmaps/python3.2.xpm", "python3.2"],
	["python3.3.desktop", "/usr/share/pixmaps/python3.3.xpm", "python3.3"],
	["python3.4.desktop", "/usr/share/pixmaps/python3.4.xpm", "python3.4"],
	# .desktop name needed ["Robomongo", "robomongo.png", "robomongo"]
	# .desktop name needed ["SmartGitHG", "smartgithg.png", "smartgithg"]
	# .desktop name needed ["Springseed", "/usr/share/pixmaps/springseed/springseed.svg", "springseed"]
	# .desktop name needed ["Synergy", "/usr/share/icons/synergy.ico", "synergy"]
	# .desktop name needed ["TimeShift", "/usr/share/pixmaps/timeshift.png", "timeshift"]
	# .desktop name needed ["Tomate", "/usr/share/tomate/media/tomate.png", "tomate"]
	# .desktop name needed ["Valentina Studio", "/opt/VStudio/Resources/vstudio.png", "vstudio"]
	# .desktop name needed ["YouTube-DL GUI", "/usr/share/pixmaps/youtube-dlg.png", "youtube-dl"]
]

# Set up for local fixes
local_check = 0
try:
	local_launchers = listdir(expanduser("~")+"/.local/share/applications")
	local_check = 1
except:
	pass

# Fixes locally located launchers 
if local_check == 1:
	if mode == "-f":
		print("\nFixing local application icons...")
	elif mode == "-u":
		print("\nUnfixing local application icons...")
	for launcher in hardcoded:
		if launcher[0] in local_launchers:
			if mode == "-f":
				print("Fixing "+launcher[0].replace(".desktop","..."))
			elif mode == "-u":
				print("Unfixing "+launcher[0].replace(".desktop","..."))
			desktop_file = open(expanduser("~")+"/.local/share/applications/"+launcher[0], 'r+')
			lines = [line for line in desktop_file]
			desktop_file.close()
			# Have to open and close so truncate works. It's a bug I'm working on.
			desktop_file = open(expanduser("~")+"/.local/share/applications/"+launcher[0], 'r+')
			desktop_file.truncate()
			desktop_file.flush()
			for n in range(0, len(lines)):
				if mode == "-f":
					if "Icon="+launcher[1] in lines[n]:
						lines.pop(n)
						lines.insert(n, "Icon="+launcher[2]+"\n")
				elif mode == "-u":
					if "Icon="+launcher[2] in lines[n]:
						lines.pop(n)
						lines.insert(n, "Icon="+launcher[1]+"\n")
			for line in lines:
				desktop_file.write(line)
			desktop_file.close()
		else:
			pass
else:
	pass

# Set up for global fixes
global_launchers = listdir("/usr/share/applications")

# Fixes globally located launchers
if mode == "-f":
	print("\nFixing global application icons...")
elif mode == "-u":
	print("\nUnfixing global application icons...")
for launcher in hardcoded:
	if launcher[0] in global_launchers:
		if mode == "-f":
			print("Fixing "+launcher[0].replace(".desktop","..."))
		elif mode == "-u":
			print("Unfixing "+launcher[0].replace(".desktop","..."))
		desktop_file = open("/usr/share/applications/"+launcher[0], 'r+')
		lines = [line for line in desktop_file]
		desktop_file.close()
		# Have to open and close so truncate works. It's a bug I'm working on.
		desktop_file = open("/usr/share/applications/"+launcher[0], 'r+')
		desktop_file.truncate()
		desktop_file.flush()
		for n in range(0, len(lines)):
			if mode == "-f":
				if "Icon="+launcher[1] in lines[n]:
					lines.pop(n)
					lines.insert(n, "Icon="+launcher[2]+"\n")
			elif mode == "-u":
				if "Icon="+launcher[2] in lines[n]:
					lines.pop(n)
					lines.insert(n, "Icon="+launcher[1]+"\n")
		for line in lines:
			desktop_file.write(line)
		desktop_file.close()
	else:
		pass

# End
if mode == "-f":
	print("\nAll hardcoded icons fixed!")
elif mode == "-u":
	print("\nAll hardcoded icons unfixed!")
