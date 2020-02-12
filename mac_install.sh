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
brew tap caffix/amass
brew install cmake tmux amass sqlmap nmap exploitdb netcat youtube-dl openvpn jenv python bat
brew tap universal-ctags/universal-ctags
brew install --HEAD universal-ctags

#using trash instead of rm
cd /tmp
curl https://github.com/sindresorhus/macos-trash/releases/download/1.1.0/trash.zip -LO
unzip trash.zip
sudo mv trash/trash /usr/local/bin
rm -r trash

#pipenv
sudo pip3 install pipenv

#vim
#Homebrew now dont accept --with-override-system-vim
brew install macvim -- --with-override-system-vim

sudo pip3 install --upgrade pynvim
sudo pip3 install --upgrade neovim


#Vim-Plug & Plugins
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugInstall

#Install ag
brew install the_silver_searcher

#Vundle & Plugins
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PluginInstall +qall

#Tmux & Plugins
git clone https://github.com/racterub/tmux-mem-cpu-load.git ~/.tmux
cd ~/.tmux/
cmake .
sudo make
sudo make install


#docker
brew cask install docker
docker pull klee/klee
curl -O  https://raw.githubusercontent.com/L4ys/LazyKLEE/master/LazyKLEE.py
chmod +x LazyKLEE.py
sudo mv LazyKLEE.py /usr/local/bin/LazyKLEE

#zsh oh-my-zsh
brew install zsh
sudo sh -c "echo $(which zsh) >> /etc/shells"
chsh -s $(which zsh)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

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
