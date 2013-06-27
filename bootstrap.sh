OPSCODE_REPO="deb http://apt.opscode.com/ precise-0.10 main"
OPSCODE_SOURCE=/etc/apt/sources.list.d/opscode.list
touch $OPSCODE_SOURCE 
grep "$OPSCODE_REPO" $OPSCODE_SOURCE > /dev/null
if [ $? -ne 0 ]; then
    echo "$OPSCODE_REPO" | sudo tee -a $OPSCODE_SOURCE 
fi

sudo apt-get install curl -q -y

sudo curl -s http://apt.opscode.com/packages@opscode.com.gpg.key | sudo apt-key add -
sudo apt-get update
echo "chef chef/chef_server_url string http://localhost:4000" >> chef.preseed
sudo debconf-set-selections chef.preseed
sudo apt-get install chef git-core -q -y
