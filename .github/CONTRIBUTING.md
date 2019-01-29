# Contribution Guidelines
These guidelines are mostly for those submitting changes to the [fix.sh](https://github.com/Foggalong/hardcode-fixer/blob/master/fix.sh) script. If your change is just adding support for a new app or otherwise a minor change then you can skip it, and thanks for contributing to the project!

## Changing the Script
This script is [made with the intent](https://github.com/Foggalong/hardcode-fixer/wiki/What,-Why-&-How) of being a standard tool that icon themes creators can reference to users as a fix for the problem of hardcoded icons. However, it is also a hobby project for me and one of the few I maintain written in bash. As such it's a bit of a learning exercise and there'll likely be parts which aren't well optimised or otherwise could be done better.

What does that mean for contributors? Well if the changes you're proposing are trivial or otherwise easily understood then you're fine. Your contributions may still be fine otherwise, it'll just take a bit longer to read through them and wrap my head around what's going on. I won't merge anything into this repo which I don't first understand fully.

However this does also mean that if your proposed changes are utilising some niche, obtuse feature of bash then it likely won't be accepted. Similarly if you're proposing a complete overhaul of the programs logic unprompted it won't be accepted because it leaves me with a codebase I didn't write and likely won't want to maintain.

## Bash
Lots have people have suggested that I switch from bash to a language like Python. The latter is arguably much better suited to a task like this and would likely make for a prettier codebase. However, I wrote the script in bash and will not be rewriting it in another language. That's not necessarily because I think bash is the best tool for the job, but I already do a lot of coding in Python for work so it's nice to have something a bit different. It (in theory) keeps my bash skills sharp while also not being a ridiculous language to use for the task.
