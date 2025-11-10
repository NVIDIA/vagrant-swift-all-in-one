# -*- mode: ruby; -*-
# vim:filetype=ruby

#
#Copyright (c) 2015-2021, NVIDIA CORPORATION.
#SPDX-License-Identifier: Apache-2.0

require 'ipaddr'

DEFAULT_BOX = "bento/ubuntu-24.04"

vagrant_box = (ENV['VAGRANT_BOX'] || DEFAULT_BOX)
username = (ENV['VAGRANT_USERNAME'] || "vagrant")

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

def load_key(path_or_contents)
  File.open(path_or_contents).read
rescue Errno::ENOENT, Errno::ENAMETOOLONG
  path_or_contents
end

local_config = {
  "username" => username,
  "full_reprovision" => (ENV['FULL_REPROVISION'] || 'false').downcase == 'true',
  "loopback_gb" => Integer(ENV['LOOPBACK_GB'] || 4),
  "extra_packages" => (ENV['EXTRA_PACKAGES'] || '').split(','),
  "storage_policies" => (ENV['STORAGE_POLICIES'] || 'default,ec').split(','),
  "ec_policy" => (ENV['EC_POLICY'] || 'ec'),
  "servers_per_port" => Integer(ENV['SERVERS_PER_PORT'] || 0),
  "replication_servers" => (ENV['REPLICATION_SERVERS'] || 'false').downcase == 'true',
  "container_auto_shard" => (ENV['CONTAINER_AUTO_SHARD'] || 'true').downcase == 'true',
  "object_sync_method" => (ENV['OBJECT_SYNC_METHOD'] || 'rsync'),
  "encryption" => (ENV['ENCRYPTION'] || 'false').downcase == 'true',
  "ssl" => (ENV['SSL'] || 'false').downcase == 'true',
  "kmip" => (ENV['KMIP'] || 'false').downcase == 'true',
  "statsd_exporter" => (ENV['STATSD_EXPORTER'] || 'false').downcase == 'true',
  "part_power" => Integer(ENV['PART_POWER'] || 10),
  "replicas" => Integer(ENV['REPLICAS'] || 3),
  "ec_type" => (ENV['EC_TYPE'] || 'liberasurecode_rs_vand'),
  "ec_replicas" => Integer(ENV['EC_REPLICAS'] || 6),
  "ec_parity" => Integer(ENV['EC_PARITY'] || 2),
  "ec_duplication" => Integer(ENV['EC_DUPLICATION'] || 1),
  "regions" => Integer(ENV['REGIONS'] || 1),
  "zones" => Integer(ENV['ZONES'] || 4),
  "nodes" => Integer(ENV['NODES'] || 4),
  "disks" => Integer(ENV['DISKS'] || 4),
  "ec_disks" => Integer(ENV['EC_DISKS'] || 8),
  "swift_repo" => (ENV['SWIFT_REPO'] || 'https://github.com/openstack/swift.git'),
  "swift_repo_branch" => (ENV['SWIFT_REPO_BRANCH'] || 'master'),
  "swiftclient_repo" => (ENV['SWIFTCLIENT_REPO'] || 'https://github.com/openstack/python-swiftclient.git'),
  "swiftclient_repo_branch" => (ENV['SWIFTCLIENT_REPO_BRANCH'] || 'master'),
  "swift_bench_repo" => (ENV['SWIFTBENCH_REPO'] || 'https://github.com/openstack/swift-bench.git'),
  "swift_bench_repo_branch" => (ENV['SWIFTBENCH_REPO_BRANCH'] || 'master'),
  "liberasurecode_repo" => (ENV['LIBERASURECODE_REPO'] || 'https://github.com/openstack/liberasurecode.git'),
  "liberasurecode_repo_branch" => (ENV['LIBERASURECODE_REPO_BRANCH'] || 'master'),
  "pyeclib_repo" => (ENV['PYECLIB_REPO'] || 'https://github.com/openstack/pyeclib.git'),
  "pyeclib_repo_branch" => (ENV['PYECLIB_REPO_BRANCH'] || 'master'),
  "extra_key" => load_key(ENV['EXTRA_KEY'] || ''),
  "source_root" => (ENV['SOURCE_ROOT'] || '/vagrant'),
  "extra_source" => (ENV['EXTRA_SOURCE'] || '/vagrant/.scratch'),
  "nvratelimit" => (ENV['NVRATELIMIT'] || 'false').downcase == 'true',
  "nvauth" => (ENV['NVAUTH'] || 'false').downcase == 'true',
}


Vagrant.configure("2") do |global_config|
  global_config.ssh.username = username
  global_config.ssh.forward_agent = true
  hosts.each do |vm_name, ip|
    global_config.vm.define vm_name do |config|
      hostname = vm_name
      if hostname == 'default' then
        hostname = (ENV['VAGRANT_HOSTNAME'] || 'saio')
      end

      config.vm.box = vagrant_box

      config.vm.provider :virtualbox do |vb, override|
        if Vagrant::Util::Platform.wsl?
          # See https://github.com/hashicorp/vagrant/issues/8604
          vb.customize [ "modifyvm", :id, "--uartmode1", "disconnected" ]
        end
        override.vm.hostname = hostname
        override.vm.network :private_network, ip: ip

        vb.name = "vagrant-#{hostname}-#{current_datetime}"
        vb.cpus = Integer(ENV['VAGRANT_CPUS'] || 1)
        vb.memory = Integer(ENV['VAGRANT_RAM'] || 2048)
        if (ENV['GUI'] || '').nil?  # Why is my VM hung on boot? Find out!
          vb.gui = true
        end
      end

      config.vm.provider "libvirt" do |lv, override|
        override.vm.hostname = hostname
        override.vm.network :private_network, :ip => ip
        lv.cpus = Integer(ENV['VAGRANT_CPUS'] || 1)
        lv.memory = Integer(ENV['VAGRANT_RAM'] || 2048)
        lv.memorybacking :access, :mode => "shared"
        override.vm.synced_folder "./", "/vagrant", type: "virtiofs"
      end

      config.vm.provider "parallels" do |prl, override|
        override.vm.hostname = hostname
        prl.name = "vagrant-#{hostname}-#{current_datetime}"
        override.vm.network :private_network, ip: ip
        prl.memory = Integer(ENV['VAGRANT_RAM'] || 2048)
        prl.cpus = Integer(ENV['VAGRANT_CPUS'] || 1)
      end

      config.vm.provider "vmware_desktop" do |vmware, override|
        override.vm.hostname = hostname
        override.vm.network :private_network, :ip => ip
        vmware.vmx["displayname"] = "vagrant-#{hostname}-#{current_datetime}"
        unless (ENV['GUI'] || '').empty?
          # use a gui to get the vm to show up in the vmware management app,
          # but they seem to stick around in the app after vagrant destroy
          vmware.gui = true
        end
        vmware.vmx["memsize"] = Integer(ENV['VAGRANT_RAM'] || 2048)
        vmware.vmx["numvcpus"] = Integer(ENV['VAGRANT_CPUS'] || 1)
      end

     if Vagrant::Util::Platform.wsl?
        hostpath = File.dirname(__FILE__)
        if !Vagrant::Util::Platform.wsl_drvfs_path? hostpath
          puts "/vagrant will be one-way-synced! Consider using a "\
               "Windows checkout, rather than keeping it under WSL."
          # DO NOT include --delete; with that, we blow away our git repos on reload
          override.vm.synced_folder hostpath, "/vagrant", type: "rsync",
            rsync__args: ["--verbose", "--archive", "-z"]
        end
      end

      config.vm.provider :aws do |v, override|
        override.vm.synced_folder ".", "/vagrant", type: "rsync",
          rsync__args: ["--verbose", "--archive", "--delete", "-z"]
        override.ssh.private_key_path = ENV['SSH_PRIVATE_KEY_PATH']

        v.access_key_id = ENV['AWS_ACCESS_KEY_ID']
        v.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
        v.region = ENV['AWS_REGION']
        v.ami = ENV['AWS_AMI']
        v.instance_type = ENV['AWS_INSTANCE_TYPE']
        v.elastic_ip = ENV['AWS_ELASTIC_IP']
        v.keypair_name = ENV['AWS_KEYPAIR_NAME']
        security_groups = ENV['AWS_SECURITY_GROUPS']
        v.security_groups = security_groups.split(',') unless security_groups.nil?
        v.tags = {'Name' => 'swift'}
      end

      config.vm.provision :chef_solo do |chef|
        chef.arguments = "--chef-license accept"
        chef.provisioning_path = "/etc/chef"
        chef.add_recipe "swift"
        chef.json = {
          "ip" => ip,
          "hostname" => hostname,
          "saio_crt_path" =>  "/etc/ssl/private/saio.crt",
        }
        chef.json.merge! local_config
        if chef.json['ssl'] then
          chef.json['base_uri'] = "https://#{hostname}"
        else
          chef.json['base_uri'] = "http://#{hostname}:8080"
        end
        chef.json['auth_uri'] = "#{chef.json['base_uri']}/auth/v1.0"
      end
    end
  end
end
