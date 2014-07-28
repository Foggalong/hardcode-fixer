#!/bin/bash

# This script handles any udpates needed to the fixing script. Normally
# this will just be downloading the new version of the script but every
# now and then something more major may occur which means other changes
# are needed. Please be aware that this script only handles updates from
# version 0.9.x onwards and is not compatible with earlier versions.

# Copyright (C) 2014
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License (version 3+) as
# published by the Free Software Foundation. You should have received
# a copy of the GNU General Public License along with this program.
# If not, see <http://www.gnu.org/licenses/>.

curl -s -o "fix.sh" 'https://raw.githubusercontent.com/Foggalong/hardcode-fixer/master/fix.sh'
