# mytty
Mytty Repository


MYTTY

myttyd.sh

Open ssh inside a tmux session.

Create a directory called ~/mytty and copy all files an directories from the source to that directory

Create lists of servers inside the ~/servers folder

ssh sessions will open inside a tmux then in the menus the sessions already open will be indicated with an *

if you want to keepalive the ssh sessions then add ServerAliveInterval 60 to /etc/ssh/ssh_config

dialogrc and tmux.conf files need to be placed in the home ddirectory. Reffer to the documentation to handle those tools

tmux.conf has the configuration needed so it will behave line screen. 
