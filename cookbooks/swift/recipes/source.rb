# python install

execute "git python-swiftclient" do
  cwd "/vagrant"
  command "git clone git://github.com/openstack/python-swiftclient.git"
  creates "/vagrant/python-swiftclient"
  action :run
end

execute "git swift" do
  cwd "/vagrant"
  command "git clone git://github.com/openstack/swift.git"
  creates "/vagrant/swift"
  action :run
end

execute "python-swiftclient-install" do
  cwd "/vagrant/python-swiftclient"
  command "pip install -e . && pip install -r test-requirements.txt"
  if not node['full_reprovision']:
    creates "/usr/local/lib/python2.7/dist-packages/python-swiftclient.egg-link"
  end
  action :run
end

execute "python-swift-install" do
  cwd "/vagrant/swift"
  command "python setup.py develop && pip install -r test-requirements.txt"
  if not node['full_reprovision']:
    creates "/usr/local/lib/python2.7/dist-packages/swift.egg-link"
  end
  action :run
end

execute "install tox" do
  command "pip install tox"
  if not node['full_reprovision']:
    creates "/usr/local/lib/python2.7/dist-packages/tox"
  end
  action :run
end

[
  'swift',
  'python-swiftclient',
].each do |dirname|
  execute "ln #{dirname}" do
    command "ln -s /vagrant/#{dirname} /home/vagrant/#{dirname}"
    creates "/home/vagrant/#{dirname}"
  end
end

