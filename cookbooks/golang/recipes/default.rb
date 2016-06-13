tarfile_name = 'go1.6.2.linux-amd64.tar.gz'

tarfile_path = "/tmp/#{tarfile_name}"
tarfile_url  = "https://storage.googleapis.com/golang/#{tarfile_name}"

remote_file "#{tarfile_path}" do
  source "#{tarfile_url}"
  owner 'root'
  group 'root'
  mode '0400'
  action :create
end

bash 'install_golang' do
  code <<-EOH
    tar -C /usr/local -xzf #{tarfile_path}
	echo "export PATH=$PATH:/usr/local/go/bin" > /etc/profile.d/golang_path.sh
    EOH
end

bash 'update_vagrant_profile' do
  code <<-EOH
    echo "export GOPATH=/vagrant" >> /home/vagrant/.profile
    echo "export PATH=$PATH:\\$GOPATH/bin" >> /home/vagrant/.profile
    echo "alias cdpfs='cd \\$GOPATH/src/github.com/swiftstack/ProxyFS'" >> /home/vagrant/.profile
    EOH
end
