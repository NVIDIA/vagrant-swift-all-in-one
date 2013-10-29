Vagrant.configure("2") do |config|
  config.vm.hostname = "swift"
  config.vm.box = "swift-all-in-one"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"
  config.vm.provider :virtualbox do |vb|
    vb.name = "swift-%d" % Time.now
  end
  config.vm.provision :chef_solo do |chef|
    chef.add_recipe "swift"
  end
end
