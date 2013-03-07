
Vagrant::Config.run do |config|
  config.vm.define :saio do |sconfig|
    sconfig.vm.box = "precise_768MB_8GBx2"
    sconfig.vm.network :hostonly, "192.168.22.66"
    sconfig.vm.customize ["modifyvm", :id, "--memory", 768]
    sconfig.vm.customize ["modifyvm", :id, "--cpus", 1]
    sconfig.vm.customize ["modifyvm", :id, "--macaddress1", "0800270ae780"]

    config.vm.provision :shell, :path => "bootstrap.sh"

    config.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = "swift-solo/chef/cookbooks"
      chef.add_recipe("swift::default")
      cfg = JSON.parse(File.read("swift-solo/chef/swift.json"))
      cfg.delete("recipes")
      chef.json = cfg
    end
  end
end
