# cd2podcast
A script to rip a CD and upload it to LibSyn.  Useful for uploading sermon podcasts.

Works in bash on Windows.

Many variables hardcoded specifically for [Daybreak Community Church](http://www.enjoydaybreak.com).

To make sure you have all the necessary packages installed on Ubuntu prior to use, run `sudo ./ubuntu_setup.sh`
Makes use of
* [box_out](http://unix.stackexchange.com/questions/70615/bash-script-echo-output-in-box)
* [crossfade.sh](https://github.com/rbouqueau/SoX/blob/master/scripts/crossfade.sh)
* [nircmd](http://www.nirsoft.net/utils/nircmd.html)
* [cdda2wav](http://www.cdda2wav.de/)
* [cdrtools - Windows binaries](https://opensourcepack.blogspot.com/p/cdrtools.html)
* [SoX](http://sox.sourceforge.net/) - Sound eXchange
* [lame project](http://lame.sourceforge.net/)
* [ncftp](http://www.ncftp.com/)
