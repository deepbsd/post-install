# Post Install Script

I use this script to set up a new Archlinux installation on my network.  It's just a way of getting
my standard software installed and my SSH and GPG keys installed.  Also to automate the installation
of the stuff I normally install every time.

## Reminders

The first thing is to remind about Pambase and Homed.  Sometimes Pambase needs to be reinstalled.
Not recently though.  Anyway, if either of those is not working, the identity of the current user
will not be validated and the ssh keys will not be usable to connect to your account on other network
hosts.

## Logfile

A logfile of all transactions is used for each operation.  It is stored in /tmp/logfile using the
LOGFILE variable.  To change just point that variable to whatever file you want to create and use.



It simply copies assets from an often-used host on my network to the current users home directory.  
This is useful for copy customized dotfiles, music collection, frequently-used tools, and other
assets.  It then installs a number of frequent 
