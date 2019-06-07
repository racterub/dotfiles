# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi


export WORKON_HOME=~/.venv
export VIRTUALENVWRAPPER_PYTHON=`which python3`
source /usr/local/bin/virtualenvwrapper.sh
source /usr/local/bin/virtualenvwrapper_lazy.sh

# enable bash-complete
if [ -r /etc/bash_completion ]; then
  . /etc/bash_completion
fi

# Powerline set
powerline-daemon -q
POWERLINE_BASH_CONTINUATION=1
POWERLINE_BASH_SELECT=1

# some more aliases
alias gdb="gdb -q"
alias tmux="tmux -2"
alias strace="strace -ixv"
alias ltrace="ltrace -iC"
alias len="expr length "
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias vi='vim'
alias objdump='objdump -M intel'

# Colorize the prompt.
yellow=$(tput setaf 3)
green=$(tput setaf 2)
blue=$(tput setaf 6)
bold=$(tput bold)
reset=$(tput sgr0)

# Setting
export TERM=screen-256color
export TERM=xterm-256color
export force_color_prompt=yes
export HISTSIZE=100000
export HISTFILESIZE=100000 
export PS1="\[$yellow$bold\]\u\[$reset\]@\[$green$bold\]\h\[$reset\]:\[$blue$bold\]\w\[$reset\]$ "
export CLICOLOR=1
export LSCOLORS='Exfxcxdxbxegedabagacad'
export EDITOR='vim'

function git_branch {
    ref=$(git symbolic-ref HEAD 2> /dev/null) || return;
    echo "("${ref#refs/heads/}") ";
}

function git_since_last_commit {
    now=`date +%s`;
    last_commit=$(git log --pretty=format:%at -1 2> /dev/null) || return;
    seconds_since_last_commit=$((now-last_commit));
    minutes_since_last_commit=$((seconds_since_last_commit/60));
    hours_since_last_commit=$((minutes_since_last_commit/60));
    minutes_since_last_commit=$((minutes_since_last_commit%60));

    echo "${hours_since_last_commit}h${minutes_since_last_commit}m ";
}

PS1="[\[\033[1;32m\]\w\[\033[0m\]] \[\033[0m\]\[\033[1;36m\]\$(git_branch)\[\033[0;33m\]\$(git_since_last_commit)\[\033[0m\]$ "
