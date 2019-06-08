#!/bin/bash


echo "+==============================+"
echo "|Deploying CTF environment.... |"
echo "+==============================+"

#overrite dot files
cp ./.gdbinit ~/

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
sudo pip3 install angr --upgrade
#Install ltrace,strace,nmap
sudo apt-get install -y nmap strace ltrace
#Install exiftool, pngcheck for forensic
sudo apt-get install -y exiftool pngcheck
sudo apt-get install -y sqlmap
sudo pip3 install ipython
sudo pip install ipython

#Install gdb,  angelboy's Pwngdb & gdb-peda
sudo apt-get install -y gdb
cd ~/
git clone https://github.com/scwuaptx/peda.git ~/.peda/
git clone https://github.com/scwuaptx/Pwngdb.git ~/.pwngdb/
echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
cp ~/.peda/.inputrc ~/
 
#Install pwntools
sudo apt-get install -y python2.7 python-pip python-dev git libssl-dev libffi-dev build-essential
sudo pip install --upgrade pwntools

#Install xortool
sudo pip install xortool


#Install Klee
curl -sSL https://get.docker.com/ | sudo sh
docker pull klee/klee
wget https://raw.githubusercontent.com/L4ys/LazyKLEE/master/LazyKLEE.py
chmod +x LazyKLEE.py
sudo mv LazyKLEE.py /usr/local/bin/LazyKLEE
sudo usermod -aG docker vagrant #change this

#Install Hashpump
sudo apt-get install -y g++ libssl-dev
cd ~/
git clone https://github.com/bwall/HashPump.git
cd HashPump/
sudo make
sudo make install
    
## z3
sudo pip3 install --upgrade z3-solver


#Install qira
cd ~/
wget -qO- https://github.com/BinaryAnalysisPlatform/qira/archive/v1.3.tar.gz | tar zx && mv qira* qira
cd qira/
sudo pip install -r requirements.txt
sudo ./install.sh
sudo ./fetchlibs.sh
sudo ./bdistrib.sh
sudo ./run_tests_static.sh

#Install binwalk
cd ~/
sudo apt-get install python-lzma
git clone https://github.com/ReFirmLabs/binwalk.git
cd binwalk/
sudo python setup.py install
sudo ./deps.sh

#Install gmpy2 & deps
$root = "/opt"
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
cd gmpy2-2.1.0.a1
sudo python setup.py build_ext --static=$root/static install


echo "===================================="
echo "|     CTF Environment Deployed     |"
echo "===================================="
echo "                          - Racterub"
