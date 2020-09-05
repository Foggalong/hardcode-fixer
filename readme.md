# Hardcoded Icon Fixer

This program aims to be a safe, easy and standardised solution to the problem of hardcoded application icons in Linux. All it is is [this one bash script](https://github.com/Foggalong/hardcode-fixer/blob/master/fix.sh) - simply copy it to somewhere on your PC and run. If you're an Arch user it's also available in the [AUR](https://aur.archlinux.org/packages/hardcode-fixer-git/).

The script requires `curl` to download the latest '[to-fix](https://github.com/Foggalong/hardcode-fixer/blob/master/tofix.csv)' list from GitHub (else Gitee or jsDelivr if that fails).


### More Info
Use `./fix.sh -h` for help, or otherwise consult [the wiki](https://github.com/Foggalong/hardcode-fixer/wiki) for:

+ An indepth explanation of [what, why, & how](https://github.com/Foggalong/hardcode-fixer/wiki/What,-Why-&-How)
+ [Use instructions](https://github.com/Foggalong/hardcode-fixer/wiki/Instructions)
+ Supported [application list](https://github.com/Foggalong/hardcode-fixer/wiki/App-Support)
+ Information on [theme support](https://github.com/Foggalong/hardcode-fixer/wiki/Theme-Support)
