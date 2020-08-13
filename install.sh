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
    sudo apt-get install -y curl build-essential cmake python-dev python-pip python3-pip git bash-completion

    sudo pip install pip --upgrade

    #set /opt's owner
    sudo chown -R $(whoami) /opt

    #Overwrite Dotfile
    cp ./.bashrc ~/
    cp ./.vimrc ~/
    cp ./.tmux.conf ~/
    cp ./.screenrc ~/
    cp ./.editorconfig ~/

    #Sourcing bashrc
    source ~/.bashrc

    #Install nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.2/install.sh | bash
    source ~/.bashrc
    nvm install v10


    #Compile vim from source
    sudo apt-get install -y libncurses5-dev libgnome2-dev libgnomeui-dev \
    libgtk2.0-dev libatk1.0-dev libbonoboui2-dev \
    libcairo2-dev libx11-dev libxpm-dev libxt-dev python-dev \
    python3-dev ruby-dev lua5.1 lua5.1-dev libperl-dev git
    sudo apt-get remove -y vim vim-runtime
    cd /opt
    git clone https://github.com/vim/vim.git
    cd vim/
    ./configure --with-features=huge \
            --enable-multibyte \
            --enable-rubyinterp=yes \
            --enable-python3interp=yes \
            --with-python3-config-dir=$(python3-config --configdir) \
            --enable-perlinterp=yes \
            --enable-luainterp=yes \
            --enable-gui=gtk2 \
            --enable-cscope \
            --prefix=/usr/local
    make VIMRUNTIMEDIR=/usr/local/share/vim/vim82
    sudo make install
    sudo update-alternatives --install /usr/bin/editor editor /usr/bin/vim 1
    sudo update-alternatives --set editor /usr/bin/vim
    sudo update-alternatives --install /usr/bin/vi vi /usr/bin/vim 1
    sudo update-alternatives --set vi /usr/bin/vim
    cd ~/
    sudo rm -rf /opt/vim

    #Install powerline-status
    #Install with python version 3 to prevent python2 EOL
    sudo pip3 install powerline-status
    sudo apt-get install -y powerline

    #Install patcher monaco font
    cd ~/dotfiles
    git clone https://github.com/powerline/fontpatcher ~/fontpatcher
    sudo apt-get install -y python-fontforge
    python ~/fontpatcher/scripts/powerline-fontpatcher monaco_powerline.ttf
    rm -rf ~/fontpatcher

    #Install ctag
    cd ~/
    sudo apt-get install -y gcc make pkg-config autoconf automake python3-docutils libseccomp-dev libjansson-dev libyaml-dev libxml2-dev
    git clone https://github.com/universal-ctags/ctags
    cd ctags/
    ./autogen.sh
    ./configure
    make
    sudo make install
    cd ../
    rm -rf ctags

    #Install for deoplete
    sudo pip3 install --upgrade pynvim
    sudo pip3 install --upgrade neovim

    #Install linters
    sudo apt-get install -y clang
    sudo pip3 install pylint
    npm install -g eslint

    #Install vim plugins
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    vim +PlugInstall

    #Install ag
    sudo apt install silversearcher-ag

    #Install tmux-memory-status
    git clone https://github.com/racterub/tmux-mem-cpu-load.git ~/.tmux
    cd ~/.tmux/
    cmake .
    sudo make
    sudo make install

    #Install virtualenv virtualenvwrapper
    sudo pip3 install virtualenv virtualenvwrapper
    sudo pip3 install pipenv
fi

echo ""
echo ""
echo "** YOU NEED TO RESTART YOUR TERMINAL OR RE-SSH TO ACTIVATE VIRTUALENV **"
echo "===================================="
echo "|        Installation Done         |"
echo "===================================="
echo "                          - Racterub"
