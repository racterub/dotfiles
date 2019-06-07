#!/bin/bash
function ask()
{
    while true; do
        read -p "$2" choice
        case $choice in
            [Yy]* )
                declare -g "$1=true"
                break;
                ;;
            [Nn]* )
                declare -g "$1=false"
                break;
                ;;
            *)
                echo "Please enter y or n"
                ;;
        esac
    done
}

ask UPGRADE "Update & upgrade every thing? (y/n): "
ask DOTFILE "Using Modified Dotfile? [including tons of plugins] (y/n): "

if $UPGRADE; then
    echo "+==========================+"
    echo "|Updating & Upgrading..... |"
    echo "+==========================+"
    sudo apt-get update
    sudo apt-get -y upgrade
    sudo apt-get -y dist-upgrade
    sudo apt-get -y autoremove
fi

if $DOTFILE; then
    echo "+===========================================+"
    echo "|Deploying Dotfile & Installing plugins.....|"
    echo "+===========================================+"

    #Install essentials
    sudo apt-get install -y build-essential cmake python-dev python-pip python3-pip git bash-completion

    #Overwrite Dotfile
    cp ./.bashrc ~/
    cp ./.vimrc ~/
    cp ./.tmux.conf ~/
    cp ./.screenrc ~/
    cp ./.editorconfig ~/

    #Compile vim from source
    sudo apt-get install -y libncurses5-dev libgnome2-dev libgnomeui-dev \
    libgtk2.0-dev libatk1.0-dev libbonoboui2-dev \
    libcairo2-dev libx11-dev libxpm-dev libxt-dev python-dev \
    python3-dev ruby-dev lua5.1 lua5.1-dev libperl-dev git
    sudo apt-get remove -y vim vim-runtime
    cd ~/
    git clone https://github.com/vim/vim.git
    cd ~/vim/
    PYTHON2_CONFIG_DIR=$(find /usr -type d -name 'config*' | grep python2 | grep -v dist-packages)
    PYTHON3_CONFIG_DIR=$(find /usr -type d -name 'config*' | grep python3 | grep -v dist-packages)
    ./configure --with-features=huge \
            --enable-multibyte \
            --enable-rubyinterp \
            --enable-python3interp \
            --with-python3-config-dir=${PYTHON3_CONFIG_DIR} \
            --enable-perlinterp \
            --enable-luainterp \
            --enable-gui=gtk2 --enable-cscope --prefix=/usr \
    sudo make VIMRUNTIMEDIR=/usr/share/vim/vim81
    sudo make install
    sudo apt-get install -y vim-runtime
    sudo update-alternatives --install /usr/bin/editor editor /usr/bin/vim 1
    sudo update-alternatives --set editor /usr/bin/vim
    sudo update-alternatives --install /usr/bin/vi vi /usr/bin/vim 1
    sudo update-alternatives --set vi /usr/bin/vim

    #Install powerline-status
    #Install with python version 3 to prevent python2 EOL 
    sudo pip3 install powerline-status
    sudo apt-get install -y fonts-powerline powerline

    #Install vim plugins
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim/
    vim +PluginInstall +qall

    #Install tmux-memory-status
    git clone https://github.com/racterub/tmux-mem-cpu-load.git ~/.tmux
    cd ~/.tmux/
    cmake .
    sudo make
    sudo make install
    
    #Install virtualenv virtualenvwrapper
    sudo pip3 install virtualenv virtualenvwrapper
fi

echo "===================================="
echo "|        Installation Done         |"
echo "===================================="
echo "                          - Racterub"
