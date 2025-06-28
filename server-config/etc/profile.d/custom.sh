#Custom Profile file
# 1.0 initial version
# 1.1 add alias
# 1/2 update path 
###################
version=1.2

export PS1='\u@\h:\w\n#'
export PATH=$PATH:$HOME/bin:/home/opc/bin

# 169.254.169.254 - Oracle cloud server for agent communication
#
#display umask values
#umask -S
#umask=022 #default
umask 0027

export PS1='\[\033[1;36m\]$PWD\[\033[0m\]\n\[\033[1;32m\]\u@\h\[\033[0m\]> '

PATH=$PATH:/usr/bin
export PATH

# END
