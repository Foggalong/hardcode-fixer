#!/bin/bash

# Fetches all supported icon themes in order to check support.

# Copyright (C) 2014
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License (version 3+) as
# published by the Free Software Foundation. You should have received
# a copy of the GNU General Public License along with this program.
# If not, see <http://www.gnu.org/licenses/>.

# elementary XFCE ✔
git clone https://github.com/shimmerproject/elementary-xfce.git

# Ardis (Kotus)
wget -O Ardis.tar.gz http://download1423.mediafire.com/3ehc3vd2vxbg/wsuc7xbqrjkh0xi/Ardis+icon+theme-0.5.tar.gz
tar xvf Ardis.tar.gz
rm -rf Ardis.tar.gz

# Flamini (Kotus)
wget -O Flamini.tar.gz http://download763.mediafire.com/20g0thn1zr4g/wet11ultqt0u4ql/Flamini-0.5.1.tar.gz
tar xvf Flamini.tar.gz
rm -rf Flamini.tar.gz

# Ursa (Kotus)
wget -O Ursa.tar.gz http://download708.mediafire.com/miu9uatwu2vg/sfb902sh3sbqqxt/Ursa+icon+theme-0.5.tar.gz
tar xvf Ursa.tar.gz
rm -rf Ursa.tar.gz

# Wrinkle (Kotus) ✔
git clone https://github.com/KotusWorks/Wrinkle.git

# Moka ✔
git clone https://github.com/moka-project/moka-icon-theme.git

# Nitrux (Nitrux) ✔
wget http://store.nitrux.in/files/nitrux-icon-theme-3.3.0.tar.gz
tar xvfz nitrux-icon-theme-3.3.0.tar.gz
rm -rf nitrux-icon-theme-3.3.0.tar.gz
# could do via ppa instead

# Compass & Dots (Nitrux) ✔
wget http://store.nitrux.in/files/compass-icon-theme-1.3.0.tar.gz
tar xvfz compass-icon-theme-1.3.0.tar.gz
rm -rf compass-icon-theme-1.3.0.tar.gz
# could do via ppa instead

# Flattr (Nitrux) ✔
git clone https://github.com/NitruxSA/flattr-icons.git

# Vibrant collection (Numix) ✔
git clone https://github.com/numixproject/numix-icon-theme-circle.git

# Mono collection (Numix) ✔
git clone https://github.com/numixproject/numix-icon-theme-utouch.git