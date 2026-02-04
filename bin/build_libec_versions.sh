set -e
cd /vagrant/liberasurecode
for t in v1.0.9 1.2.0 1.3.1 1.4.0 1.5.0 1.6.0 1.6.1 ; do
    git checkout $t
    make clean >/dev/null 2>&1
    ./autogen.sh >/dev/null 2>&1
    ./configure >/dev/null 2>&1
    make >/dev/null 2>&1
    sudo make install >/dev/null 2>&1
done
