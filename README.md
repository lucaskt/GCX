Galactic Cruise X
=================

This is a very old project from my early teens (circa 2001) that I found lying around in my HDD.
It's a very rudimentary shooter, but it illustrates the skeleton of a game being built.

The code does contain some smart techniques, such as pre-allocation of objects so that it doesn't have to spend time on allocation later. But it also does not go as far as building free-lists and does linear searches for empty elements, so YMMV.

![screenshot](/gcx.gif)

What impressed me, though, is that it's extremely well documented, apart from havin a rudimentary build system in place (a couple of BAT files, aside from expecting some system variables set).

Besides this README file, there is an INFO.TXT file I kept because it belonged to the original game when I released it.

Running
-------

I could get it to run on dosbox by having QB45 in a directory, this source code in another and then doing
`dosbox -c 'mount c GCX' -c 'mount d QB45' -c 'SET PATH=D:'`

then once in Dosbox, just:
```
Z:/> C:
C:/> EDIT
```

Building
--------

There are a couple of Real Mode DOS assembly libs in there, you'll need TASM if you want to build them with my scaffolding.
Just mount TASM somewhere and run Libs/BUILDLIB.BAT with a TASMDIR environment variable set.

Code highlights:
* Surprisingly well organized and documented
* Simple example of assembly+QB integration
* A few smart-ish uses of data structures
* Excceedingly funny comments such as claims for me to be "running short on time to work on projects such as this"
	- at that point in my life I mainly attended school and played guitar
