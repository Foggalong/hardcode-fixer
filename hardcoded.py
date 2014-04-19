class Hardcoded:
	def __init__(self,desktop_file,default_icon_location,icon_theme_name):
		self.desktop_file = desktop_file
		self.default_icon_location = default_icon_location
		self.icon_theme_name = icon_theme_name

	#Returns desktopfile name
	def getDesktopFile(self):
		return self.desktop_file

	#Returns current icon location
	def getDefaultIconLocation(self):
		return self.default_icon_location

	#Returns icon name in theme 
	def getIconThemeName(self):
		return self.icon_theme_name

	#Replaces the icon line in desktopfile to the icon name in theme
	def fix(self,location):
		desktop_file = open(location + self.getDesktopFile(), 'r+')
		lines = [line for line in desktop_file]
		desktop_file.close()
		# Have to open and close so truncate works. It's a bug I'm working on.
		desktop_file = open(location + self.getDesktopFile(), 'r+')
		desktop_file.truncate()
		desktop_file.flush()
		for n in range(0, len(lines)):
			if "Icon=" + self.getDefaultIconLocation() in lines[n]:
				lines.pop(n)
				lines.insert(n, "Icon=" + self.getIconThemeName() + "\n")
		for line in lines:
			desktop_file.write(line)
		desktop_file.close()

	#Replaces the icon line in desktopfile to the default icon location
	def unfix(self,location):
		desktop_file = open(location + self.getDesktopFile(), 'r+')
		lines = [line for line in desktop_file]
		desktop_file.close()
		# Have to open and close so truncate works. It's a bug I'm working on.
		desktop_file = open(location + self.getDesktopFile(), 'r+')
		desktop_file.truncate()
		desktop_file.flush()
		for n in range(0, len(lines)):
			if "Icon=" + self.getIconThemeName() in lines[n]:
				lines.pop(n)
				lines.insert(n, "Icon=" + self.getDefaultIconLocation() + "\n")
		for line in lines:
			desktop_file.write(line)
		desktop_file.close()
