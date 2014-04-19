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
from hardcoded import Hardcoded

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
hardcoded_list = [
	# .desktop name needed Hardcoded("Android Studio", "/opt/android-studio/bin/idea.png", " androidstudio")
	# .desktop name needed Hardcoded("Aptik", "/usr/share/pixmaps/aptik.png", "aptik")
	# .desktop name needed Hardcoded("Arista", "/usr/share/arista/ui/icon.svg", "arista")
	Hardcoded("Bastion.desktop", "steam", "steam_icon_107100"),
	# .desktop name needed Hardcoded("Conky Manager", " /usr/share/pixmaps/conky-manager.png", " conky-manager")
	# .desktop name needed Hardcoded("Dogecoin-qt (AUR)", "/usr/share/pixmaps/dogecoin.png", "dogecoin")
	Hardcoded("Dota 2.desktop", "steam", "steam_icon_570"),
	# .desktop name needed Hardcoded("Driver Manager", "/usr/share/icons/hicolor/scalable/apps/driver-manager.svg", "jockey")
	# .desktop name needed Hardcoded("Easy Life", "/usr/share/pixmaps/easylife.png", "easylife")
	# .desktop name needed Hardcoded("Fade In", "/usr/share/fadein/icon_app/fadein_icon_128x128.png", "fadein")
	Hardcoded("formatjunkie.desktop", "/opt/extras.ubuntu.com/formatjunkie/pixmap/fjt.png", "fjt"),
	# .desktop name needed Hardcoded("Gcolor2", " /usr/share/pixmaps/gcolor2/gcolor2.xpm", "gcolor2")
	Hardcoded("gespeaker.desktop", "/usr/share/gespeaker/data/icons/gespeaker.svg", "gespeaker"),
	# .desktop name needed Hardcoded("GNOME Weather", "org.gnome.Weather.Application", "gnome-weather")
	Hardcoded("guvcview.desktop", "/usr/share/pixmaps/guvcview/guvcview.png", "guvcview"),
	Hardcoded("www.octave.org-octave.desktop", "/usr/share/octave/3.6.4/imagelib/octave-logo.svg", "octave"),
	# .desktop name needed Hardcoded("Graphic Network Simulator", "/usr/share/pixmaps/gns3.xpm", "gns")
	Hardcoded("grisbi", "/usr/share/pixmaps/grisbi/grisbi.svg", "grisbi"),
	# .desktop name needed Hardcoded("HipChat", "hipchat.png", "hipchat")
	# .desktop name needed Hardcoded("Intel Graphics Installer", "/usr/share/intel-linux-graphics-installer/images/logo.png", "intel-installer")
	# .desktop name needed Hardcoded("IntelliJ IDEA", "/opt/idea-IC/bin/idea.png", "idea")
	Hardcoded("Kerbal Space Program.desktop", "steam", "steam_icon_220200"),
	Hardcoded("Left 4 Dead 2.desktop", "steam", "steam_icon_550"),
	Hardcoded("Left 4 Dead 2 Beta.desktop", "steam", "steam_icon_223530"),
	# .desktop name needed Hardcoded("Lightworks", "/usr/share/lightworks/Icons/App.png", "lightworks")
	# .desktop name needed Hardcoded("Lucky Backup", "/usr/share/pixmaps/luckybackup.png", "luckybackup")
	# .desktop name needed Hardcoded("Master PDF Editor", "/opt/master-pdf-editor/master-pdf-editor.png", "master-pdf-editor")
	# .desktop name needed Hardcoded("My Weather Indicator", "/opt/extras.ubuntu.com/my-weather-indicator/share/pixmaps/my-weather-indicator.png", "indicator-weather")
	Hardcoded("netbeans.desktop", "/usr/share/netbeans/7.0.1/nb/netbeans.png", "netbeans"),
	# .desktop name needed Hardcoded("Ninja IDE", "/usr/share/ninja-ide/img/icon.png", "ninja-ide")
	# .desktop name needed Hardcoded("Nitro", "/usr/share/nitrotasks/media/nitrotasks.png", "nitrotasks")
	# .desktop name needed Hardcoded("OmegaT", "/usr/share/omegat/images/OmegaT.xpm", "omegat")
	# .desktop name needed Hardcoded("Oracle SQL Developer", "/opt/oracle-sqldeveloper/icon.png", "N/A")
	# .desktop name needed Hardcoded("PacmanXG", "/usr/share/pixmaps/pacmanxg.png", "pacmanxg")
	# .desktop name needed Hardcoded("Pamac (Install)", "/usr/share/pamac/icons/32x32/apps/pamac.png", "system-software-install")
	# .desktop name needed Hardcoded("Pamac (Update)", "/usr/share/pamac/icons/32x32/apps/pamac.png", "system-software-update")
	# .desktop name needed Hardcoded("PHP Storm", "PhpStorm-133.803/bin/webide.png", "phpstorm")
	# .desktop name needed Hardcoded("Pycharm", "/home/radio/Descargas/pycharm-community-3.1.1/bin/pycharm.png", "pycharm")
	Hardcoded("python2.6.desktop", "/usr/share/pixmaps/python2.6.xpm", "python2.6"),
	Hardcoded("python2.7.desktop", "/usr/share/pixmaps/python2.7.xpm", "python2.7"),
	Hardcoded("python3.0.desktop", "/usr/share/pixmaps/python3.0.xpm", "python3.0"),
	Hardcoded("python3.1.desktop", "/usr/share/pixmaps/python3.1.xpm", "python3.1"),
	Hardcoded("python3.2.desktop", "/usr/share/pixmaps/python3.2.xpm", "python3.2"),
	Hardcoded("python3.3.desktop", "/usr/share/pixmaps/python3.3.xpm", "python3.3"),
	Hardcoded("python3.4.desktop", "/usr/share/pixmaps/python3.4.xpm", "python3.4"),
	# .desktop name needed Hardcoded("Robomongo", "robomongo.png", "robomongo")
	# .desktop name needed Hardcoded("SmartGitHG", "smartgithg.png", "smartgithg")
	# .desktop name needed Hardcoded("Springseed", "/usr/share/pixmaps/springseed/springseed.svg", "springseed")
	# .desktop name needed Hardcoded("Synergy", "/usr/share/icons/synergy.ico", "synergy")
	# .desktop name needed Hardcoded("TimeShift", "/usr/share/pixmaps/timeshift.png", "timeshift")
	# .desktop name needed Hardcoded("Tomate", "/usr/share/tomate/media/tomate.png", "tomate")
	# .desktop name needed Hardcoded("Valentina Studio", "/opt/VStudio/Resources/vstudio.png", "vstudio")
	# .desktop name needed Hardcoded("YouTube-DL GUI", "/usr/share/pixmaps/youtube-dlg.png", "youtube-dl")
]

def fixAll():
	# Set up for local fixes
	local_check = 0
	try:
		local_launchers = listdir(expanduser("~")+"/.local/share/applications")
		local_check = 1
	except:
		pass

	# Set up for global fixes
	global_launchers = listdir("/usr/share/applications")

	# Fixes locally located launchers 
	for icon in hardcoded_list:
		if local_check == 1:
			if icon.getDesktopFile() in local_launchers:
				icon.fix(local_launchers)
			else:
				pass
		else:
			pass

		if icon.getDesktopFile() in global_launchers:
			icon.fix(global_launchers)
		else:
			pass

def unfixAll():
	# Set up for local unfixes
	local_check = 0
	try:
		local_launchers = listdir(expanduser("~")+"/.local/share/applications")
		local_check = 1
	except:
		pass

	# Set up for global unfixes
	global_launchers = listdir("/usr/share/applications")

	# Fixes locally located launchers 
	for icon in hardcoded_list:
		if local_check == 1:
			if icon.getDesktopFile() in local_launchers:
				icon.unfix(local_launchers)
			else:
				pass
		else:
			pass

		if icon.getDesktopFile() in global_launchers:
			icon.unfix(global_launchers)
		else:
			pass
