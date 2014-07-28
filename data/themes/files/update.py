#!/usr/bin/python3

# Requires git, wget and the following modules
from os import chdir, listdir, system
from time import sleep

# Gets data
system("wget 'https://raw.githubusercontent.com/Foggalong/hardcode-fixer/master/data/list/tofix.csv'")
tofix = open("tofix.csv", 'r')
app_name, app_data = [], []
for line in tofix:
	app_name.append(line.split(",")[0].strip())
	app_data.append(line.split(",")[3].strip())



# elementary XFCE
# ===============

# Sets up files
exfce_file = open('exfce.md', 'w')
exfce_intro = [
	"elementary XFCE\n",
	"================\n\n"
	"The elementary icon theme project was one of the most popular icon theme projects of it's time but with the creation of eOS the scope of the project has changed from a full theme to a ditro specific one. This lead to all sorts of forks to continue the maintainance, the most popular of which being [elementary XFCE](https://github.com/shimmerproject/elementary-xfce).\n\n",
	'The theme comes in four "shades": normal, dark, darker and darkest, all of which can be found on [their GitHub page](https://github.com/shimmerproject/elementary-xfce).\n\n',
	"| Application Name | Normal | Dark | Darker | Darkest |\n",
	"| :---------------: | :---------------: | :---------------: | :---------------: | :---------------: |\n"
	]

# One repo covers all themes
system("git clone https://github.com/shimmerproject/elementary-xfce.git")
chdir("elementary-xfce/elementary-xfce/apps/48/")

# Removes file extension from icons
exfce_icons = [ name.replace(".svg", "") for name in listdir() ]

# Checks whether icon covered
exfce_data = []
for x in range(1, len(app_data)-1):
	if app_data[x] in exfce_icons:
		exfce_data.append("| "+app_name[x]+" | ✔ | ✔ | ✔ | ✔ |\n")
	else:
		exfce_data.append("| "+app_name[x]+" |   |   |   |   |\n")

# Writes to data file
for line in exfce_intro+exfce_data:
	exfce_file.write(line)

chdir("../../../../")


# Kotus Works
# ===============

# Sets up files
kotus_file = open('kotus.md', 'w')
kotus_intro = [
	"KotusWorks\n",
	"================\n\n"
	"[KotusWorks](http://kotusworks.deviantart.com/) is relatively new to the icon design game but already has two beta releases for icon themes: [Ardis](http://kotusworks.deviantart.com/art/Ardis-Icon-Theme-450178304?q=gallery%3AKotusWorks&qo=0) and [Flamini](http://kotusworks.deviantart.com/art/Flamini-icons-set-for-KDE-437738820?q=gallery%3AKotusWorks&qo=2), the latter of which also comes in Colorful and White variants.\n\n",
	"| Application Name | Ardis | Flamini | F. Colorful | F. White | Ursa | Wrinkle |\n",
	"| :---------------: | :---------------: | :---------------: | :---------------: | :---------------: | :---------------: | :---------------: |\n"
	]

# Ardis theme
# ---------------

# Gets source
system("wget http://download1423.mediafire.com/3ehc3vd2vxbg/wsuc7xbqrjkh0xi/Ardis+icon+theme-0.5.tar.gz")
system("tar xvfz Ardis+icon+theme-0.5.tar.gz")
chdir("Ardis icon theme/48x48/apps/")

# Removes file extension from icons
ardis_icons = [ name.replace(".png", "") for name in listdir() ]

# Checks whether icon covered
ardis_data = []
for x in range(1, len(app_data)-1):
	if app_data[x] in ardis_icons:
		ardis_data.append("✔")
	else:
		ardis_data.append(" ")

chdir("../../../")


# Flamini theme
# ---------------

# Gets source
system("wget http://download1423.mediafire.com/3ehc3vd2vxbg/wsuc7xbqrjkh0xi/Ardis+icon+theme-0.5.tar.gz")
system("tar xvfz Ardis+icon+theme-0.5.tar.gz")
chdir("Ardis icon theme/48x48/apps/")

# system("wget http://download763.mediafire.com/20g0thn1zr4g/wet11ultqt0u4ql/Flamini-0.5.1.tar.gz")
# sleep(5)
# system("tar xf Flamini-0.5.1.tar.gz")
# chdir("Flamini-0.5.1/Flamini/scalable/apps/")

# Removes file extension from icons
flamini_icons = [ name.replace(".svg", "") for name in listdir() ]

# Checks whether icon covered
flamini_data = []
for x in range(1, len(app_data)-1):
	if app_data[x] in flamini_icons:
		flamini_data.append("✔")
	else:
		flamini_data.append(" ")

chdir("../../../")


# Ursa theme
# ---------------

# Gets source
system("wget http://download708.mediafire.com/miu9uatwu2vg/sfb902sh3sbqqxt/Ursa+icon+theme-0.5.tar.gz")
system("tar xvfz Ursa+icon+theme-0.5.tar.gz")
chdir("Ursa icon theme/48x48/apps/")

# Removes file extension from icons
ursa_icons = [ name.replace(".png", "") for name in listdir() ]

# Checks whether icon covered
ursa_data = []
for x in range(1, len(app_data)-1):
	if app_data[x] in ursa_icons:
		ursa_data.append("✔")
	else:
		ursa_data.append(" ")

chdir("../../../")


# Wrinkle theme
# ---------------

# Gets source
system("git clone https://github.com/KotusWorks/Wrinkle.git")
chdir("Wrinkle - Desktop/")

# Removes file extension from icons
wrinkle_icons = [ name.replace(".svg", "") for name in listdir() ]

# Checks whether icon covered
wrinkle_data = []
for x in range(1, len(app_data)-1):
	if app_data[x] in wrinkle_icons:
		wrinkle_data.append("✔")
	else:
		wrinkle_data.append(" ")


# Checks whether icon covered
kotus_data = []
for x in range(1, len(app_data)-1):
	kotus_data.append("| "+app_name[x]+" | "+ardis_data[x]+" | "+flamini_data[x]+" | "+flamini_data[x]+" | "+flamini_data[x]+" | "+ursa_data[x]+" | "+wrinkle_data[x]+" |\n")

# Writes to data file
for line in kotus_intro+kotus_data:
	kotus_file.write(line)

chdir("../../")


# Clean up
system("rm tofix.csv")