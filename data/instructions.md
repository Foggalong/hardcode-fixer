# Instructions

### Dependencies
The only dependency of the script is ```curl``` which is used for fetching relevant information from this GitHub. This is included on almost all distributions by default but those of you who're using something a bit more adventerous (looking at you Arch users) may have to install it.


### Usage
Simply download [fix.sh](https://github.com/Foggalong/hardcode-fixer/blob/master/fix.sh) - that's all you need! Running it provides a few options:

+  ```sudo ./fix.sh``` will fix launcher both in ```/usr/share/applications/``` and ```~/.local/share/applications/```. This is the reccomended usage.

+ ```./fix.sh``` will fix only launchers located in ```~/.local/share/applications/```. This is only reccomended if you are not able to use root.


### Flags
There are also several options for flags:

+ ```-l, --local```
The same as running ```./fix.sh```

+ ```-r, --revert```
Reverts any changes made. Whether it is to be run as root or not depends on how it was used initially.

+ ```-h, --help```
Displays this help menu.

+ ```-v, --version```
Print version number.
