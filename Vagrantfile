require 'ipaddr'

base_ip = IPAddr.new(ENV['IP'] || "192.168.8.80")
hosts = {
  'default' => base_ip.to_s
}
extra_vms = Integer(ENV['EXTRA_VMS'] || 0)
(1..extra_vms).each do |i|
  base_ip = base_ip.succ
  hosts["node#{i}"] = base_ip.to_s
end

current_datetime = Time.now.strftime("%Y%m%d-%H%M%S")

local_config = {
  "full_reprovision" => (
        ENV['FULL_REPROVISION'] || 'false'
    ).downcase == 'true',
  "loopback_gb" => Integer(ENV['LOOPBACK_GB'] || 4),
  "extra_packages" => (ENV['EXTRA_PACKAGES'] || '').split(','),
  "storage_policies" => (ENV['STORAGE_POLICIES'] || '').split(','),
  "ec_policy" => (ENV['EC_POLICY'] || ''),
  "object_sync_method" => (ENV['OBJECT_SYNC_METHOD'] || 'rsync'),
  "part_power" => Integer(ENV['PART_POWER'] || 10),
  "replicas" => Integer(ENV['REPLICAS'] || 3),
  "regions" => Integer(ENV['REGIONS'] || 1),
  "zones" => Integer(ENV['ZONES'] || 4),
  "nodes" => Integer(ENV['NODES'] || 4),
  "disks" => Integer(ENV['DISKS'] || 4),
  "swift_repo" => (ENV['SWIFT_REPO'] || 'git://github.com/openstack/swift.git'),
  "swiftclient_repo" => (ENV['SWIFTCLIENT_REPO'] || 'git://github.com/openstack/python-swiftclient.git'),
  "swift_bench_repo" => (ENV['SWIFTBENCH_REPO'] || 'git://github.com/openstack/swift-bench.git'),
  "swift_specs_repo" => (ENV['SWIFTSPECS_REPO'] || 'git://github.com/openstack/swift-specs.git'),
}


Vagrant.configure("2") do |global_config|
  global_config.ssh.forward_agent = true
  hosts.each do |vm_name, ip|
    global_config.vm.define vm_name do |config|
      hostname = vm_name
      if hostname == 'default' then
          hostname = 'saio'
      end
      config.vm.hostname = hostname
      config.vm.box = "swift-all-in-one"
      config.vm.box_url = "http://files.vagrantup.com/precise64.box"
      config.vm.network :private_network, ip: ip
      config.vm.provider :virtualbox do |vb|
        vb.name = "vagrant-#{hostname}-#{current_datetime}"
        vb.memory = 768
      end
      config.vm.provision :chef_solo do |chef|
        chef.add_recipe "swift"
        chef.json = local_config
      end
    end
  end
end
