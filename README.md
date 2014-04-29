Hardcoded Icon Fixer
==============
This program aims to be a safe, easy and standardised soltuion to the problem of hardcoded application icons in Linux. All it is is [this one bash script](https://github.com/Foggalong/hardcode-fixer/blob/master/fix.sh) - simply copy it to somewhere on your PC and run (```./fix.sh -h``` for help). For a list of supported icons see [this list](https://github.com/Foggalong/hardcode-fixer/blob/master/data/list.md).

### What are hardcoded icons?
The standard locations for storing an applications icons are ```/usr/share/icons/hicolor/[size]/apps/[icon name]``` and ```~/.local/share/icons/hicolor/[size]/apps/[icon name]```. However, some developers choose to hardcode their icons by putting them elsewhere making it impossible for icon themes to change them. This is a bad practice as it leads to users
 changing launcher filers to complete thems which can result in breakage later on.

### What should be done?
Report it! It is an issue that should be reported to the relevant bug trackers, and the developer(s) should fix it as soon as possible. But what about when this can't be done? What if the program isn't supported, the developer is unreachable or worse – stubborn?!

### ...well?
That's where this script comes in. It goes through out database of hardcoded icons and makes any corrections on your system that need to be made. It needs root access as they are mostly stored in root locations but is completely secure and open source for your examination. It makes the change by copying the original icon to the standard location and changing the launcher to reflect the move. This means that regardless of the theme you use there'll be no breakage.

### What about themeing?
When fixing the icons it changes the name to a standardised one from our database. The designers of icon themes then simply create icons with names from our list and so when their theme is applied everything will work flawlessly.

### Which icon themes support it?
Currently [elementary XFCE](https://github.com/shimmerproject/elementary-xfce), [KotusWorks](http://kotusworks.deviantart.com/), [Moka](http://mokaproject.com/), [Nitrux](http://nitrux.in/) and [Numix](http://numixproject.org/). We're constantly contacting designers and developers to get them involved. If you are one, [give me an email](mailto:joshua.h.fogg@gmail.com) and we'll talk about getting you on board. To see which icons are supported within each theme see [this list](https://github.com/Foggalong/hardcode-fixer/blob/master/data/themesupport.md).

### I'm not a designer or developer! How can I help?
[Report any applications](https://github.com/Foggalong/hardcode-fixer/issues) you find with hardcoded icons to us so that we can have the most complete fixer possible. Every little helps!
