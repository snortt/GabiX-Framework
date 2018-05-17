# ~/.bashrc: executed by bash(1) for non-login shells.

# Note: PS1 and umask are already set in /etc/profile. You should not
# need this unless you want different defaults for root.
# PS1='${debian_chroot:+($debian_chroot)}\h:\w\$ '
# umask 022

if [ -f /etc/cores.defs ]; then
    . /etc/cores.defs
    PS1="${TVERDEB}__NOMESTR_SYS__ ${TBRANCOB}\W ${TAMARELOB}\\$ $RESET"
fi

# You may uncomment the following lines if you want `ls' to be colorized:
export LS_OPTIONS='--color=auto'
eval "`dircolors`"
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -lha'
alias l='ls $LS_OPTIONS -lh'
alias df='df -h'
alias du='du -h --max-depth=1'
alias free='free -mt'

# Some more alias to avoid making mistakes:
# alias rm='rm -i'
# alias cp='cp -i'
# alias mv='mv -i'
