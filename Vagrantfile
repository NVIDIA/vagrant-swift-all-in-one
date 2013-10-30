Vagrant.configure("2") do |config|
  config.vm.hostname = "swift"
  config.vm.box = "swift-all-in-one"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"
  config.vm.provider :virtualbox do |vb|
    vb.name = "swift-%d" % Time.now
  end
  config.vm.provision :chef_solo do |chef|
    chef.add_recipe "swift"
    chef.json = {
      "extra_packages" => (ENV['EXTRA_PACKAGES'] || '').split(','),
      "part_power" => Integer(ENV['PART_POWER'] || 10),
      "replicas" => Integer(ENV['REPLICAS'] || 3),
      "regions" => Integer(ENV['REGIONS'] || 1),
      "zones" => Integer(ENV['ZONES'] || 4),
      "nodes" => Integer(ENV['NODES'] || 4),
      "disks" => Integer(ENV['DISKS'] || 4),
    }
  end
end
