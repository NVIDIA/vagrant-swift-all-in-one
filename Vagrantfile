Vagrant.configure("2") do |config|
  config.ssh.forward_agent = true
  config.vm.hostname = "saio"
  config.vm.box = "swift-all-in-one"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"
  config.vm.network :private_network, ip: ENV['IP'] || "192.168.8.80"
  config.vm.provider :virtualbox do |vb|
    vb.name = "swift-aio-%s" % Time.now.strftime("%Y%m%d")
  end
  config.vm.provision :chef_solo do |chef|
    chef.add_recipe "swift"
    chef.json = {
      "full_reprovision" => (
              ENV['FULL_REPROVISION'] || 'false'
          ).downcase == 'true',
      "extra_packages" => (ENV['EXTRA_PACKAGES'] || '').split(','),
      "storage_policies" => (ENV['STORAGE_POLICIES'] || '').split(','),
      "object_sync_method" => (ENV['OBJECT_SYNC_METHOD'] || 'rsync'),
      "part_power" => Integer(ENV['PART_POWER'] || 10),
      "replicas" => Integer(ENV['REPLICAS'] || 3),
      "regions" => Integer(ENV['REGIONS'] || 1),
      "zones" => Integer(ENV['ZONES'] || 4),
      "nodes" => Integer(ENV['NODES'] || 4),
      "disks" => Integer(ENV['DISKS'] || 4),
    }
  end
end
