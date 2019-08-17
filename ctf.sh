#!/bin/bash


echo "+==============================+"
echo "|Deploying CTF environment.... |"
echo "+==============================+"

#overrite dot files
cp ./.gdbinit ~/

#set /opt's owner
sudo chown -R $(whoami) /opt

#Update & upgrade
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove
#Install multi-arch
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install -y gcc-multilib

#Install angr
sudo apt-get -y install python-dev libffi-dev build-essential virtualenvwrapper
sudo -H pip3 install angr --upgrade
#Install ltrace,strace,nmap
sudo apt-get install -y nmap strace ltrace
#Install exiftool, pngcheck for forensic
sudo apt-get install -y exiftool pngcheck sqlmap

#Install ipython2/3
sudo -H pip3 install ipython

#Install gdb,  angelboy's Pwngdb & gdb-peda
sudo apt-get install -y gdb
cd ~/
git clone https://github.com/scwuaptx/peda.git ~/.peda/
git clone https://github.com/scwuaptx/Pwngdb.git ~/.pwngdb/
echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
cp ~/.peda/.inputrc ~/

#Install pwntools
sudo apt-get install -y python2.7 python-pip python-dev git libssl-dev libffi-dev build-essential
sudo -H pip install --upgrade pwntools

#Install xortool
sudo -H pip install xortool


#Install Klee
curl -sSL https://get.docker.com/ | sudo sh

#Install Hashpump
sudo apt-get install -y g++ libssl-dev
cd /opt
git clone https://github.com/bwall/HashPump.git
cd HashPump/
sudo make
sudo make install

## z3
sudo -H pip3 install --upgrade z3-solver

#Install msfconsole
mkdir /opt/msf
cd /opt/msf
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall && chmod 755 msfinstall && sudo ./msfinstall

#Install searchsploit
git clone https://github.com/offensive-security/exploitdb.git /opt/exploitdb
sed 's|path_array+=(.*)|path_array+=("/opt/exploitdb")|g' /opt/exploitdb/.searchsploit_rc > ~/.searchsploit_rc
sudo ln -sf /opt/exploitdb/searchsploit /usr/local/bin/searchsploit

#Install jtr
cd /opt
git clone https://github.com/magnumripper/JohnTheRipper
sudo apt-get -y install build-essential libssl-dev git zlib1g-dev yasm libgmp-dev libpcap-dev pkg-config libbz2-dev
cd JohnTheRipper/src
sudo ./configure && sudo make -s clean && sudo make -sj4

#Install qira
cd /opt
wget -qO- https://github.com/BinaryAnalysisPlatform/qira/archive/v1.3.tar.gz | tar zx && mv qira* qira
cd qira/
sudo -H pip install -r requirements.txt
sudo ./install.sh
sudo ./fetchlibs.sh
sudo ./bdistrib.sh
sudo ./run_tests_static.sh

#Install binwalk
cd /opt
sudo apt-get install python-lzma
git clone https://github.com/ReFirmLabs/binwalk.git
cd binwalk/
sudo python3 setup.py install
sudo ./deps.sh

#Install gmpy2 & deps
root = "/opt"
sudo mkdir -p $root/src
sudo mkdir -p $root/static

#Install m4
cd $root/src
sudo wget https://ftp.gnu.org/gnu/m4/m4-1.4.18.tar.gz
sudo tar zxvf m4-1.4.18.tar.gz
cd m4-1.4.18
sudo ./configure --prefix=/usr/local
sudo make
sudo make check
sudo make install

#Install gmp
cd $root/src
sudo wget https://gmplib.org/download/gmp/gmp-6.1.2.tar.xz
sudo tar Jxvf gmp-6.1.2.tar.xz
cd gmp-6.1.2
sudo ./configure --prefix=$root/static --enable-static --disable-shared --with-pic
sudo make
sudo make check
sudo make install

#Install mpfr
cd $root/src
sudo wget https://www.mpfr.org/mpfr-current/mpfr-4.0.2.tar.xz
sudo tar Jxvf mpfr-4.0.2.tar.xz
cd mpfr-4.0.2
sudo ./configure --prefix=$root/static --enable-static --disable-shared --with-pic --with-gmp=$root/static
sudo make
sudo make check
sudo make install

#Install mpc
cd $root/src
sudo wget ftp://ftp.gnu.org/gnu/mpc/mpc-1.1.0.tar.gz
sudo tar zxvf mpc-1.1.0.tar.gz
cd mpc-1.1.0
sudo ./configure --prefix=$root/static --enable-static --disable-shared --with-pic --with-gmp=$root/static --with-mpfr=$root/static
sudo make
sudo make check
sudo make install

#Install gmpy2
cd $root/src
sudo wget https://github.com/aleaxit/gmpy/releases/download/gmpy2-2.1.0a1/gmpy2-2.1.0a1.tar.gz
sudo tar zxvf gmpy2-2.1.0a1.tar.gz
cd gmpy2-2.1.0a1
sudo python setup.py build_ext --static=$root/static install


echo "===================================="
echo "|     CTF Environment Deployed     |"
echo "===================================="
echo "                          - Racterub"
