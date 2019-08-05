#!/bin/bash


COLOR_RED='\033[1;31m'
COLOR_RESET='\033[0m'

if type xcode-select >&- && xpath=$( xcode-select --print-path ) &&
   test -d "${xpath}" && test -x "${xpath}" ; then
    :
else
   echo -e "${COLOR_RED}Your Xcode Command-Line tool is not installed"
   echo -e "Installing Xcoode Command-Line tool${COLOR_RESET}"
   xcode-select --install
   exit
fi

which -s brew
if [[ $? != 0 ]] ; then
    # Install Homebrew
    echo -e "${COLOR_RED}Brew not installed${COLOR_RESET}"
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
    brew update
fi


echo "+==========================+"
echo "|Updating & Upgrading..... |"
echo "+==========================+"

#configs
cp ./.zshrc ~/
cp ./.vimrc ~/
cp ./.tmux.conf ~/

#Install tools via Homebrew
brew tap
brew install cmake tmux


#vim
#Homebrew now dont accept --with-override-system-vim
brew install macvim -- --with-override-system-vim

#Vundle & Plugins
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim/
vim +PluginInstall +qall

#Tmux & Plugins
brew install tmux
git clone https://github.com/racterub/tmux-mem-cpu-load.git ~/.tmux
cd ~/.tmux/
cmake .
sudo make
sudo make install

#virtualenv virtualenvwrapper
sudo pip3 install virtualenv virtualenvwrapper

#docker
brew cask install docker

#font
cp ./monaco_powerline.ttf /Users/macintosh/Library/Fonts/

#zsh oh-my-zsh
brew install zsh
sudo sh -c "echo $(which zsh) >> /etc/shells" 
sudo chsh -s $(which zsh)
sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

#zsh theme - powerlevel9k
git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k

#zsh plugin
git clone git://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions
brew install zsh-syntax-highlighting

source ~/.zshrc

echo "===================================="
echo "|        Installation Done         |"
echo "===================================="
echo "                          - Racterub"
