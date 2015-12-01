# Copyright (c) 2015 SwiftStack, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require 'ipaddr'

DEFAULT_BOX = 'swift-all-in-one'

vagrant_boxes = {
  DEFAULT_BOX => 'https://atlas.hashicorp.com/ubuntu/boxes/trusty64/versions/14.04/providers/virtualbox.box',
  'precise' => 'http://files.vagrantup.com/precise64.box',
  'trusty' => 'https://atlas.hashicorp.com/ubuntu/boxes/trusty64/versions/14.04/providers/virtualbox.box',
}
vagrant_box = (ENV['VAGRANT_BOX'] || DEFAULT_BOX)

base_ip = IPAddr.new(ENV['IP'] || '192.168.8.80')
hosts = {
  'default' => base_ip.to_s
}
extra_vms = Integer(ENV['EXTRA_VMS'] || 0)
(1..extra_vms).each do |i|
  base_ip = base_ip.succ
  hosts["node#{i}"] = base_ip.to_s
end

current_datetime = Time.now.strftime('%Y%m%d-%H%M%S')

local_config = {
  'full_reprovision' => (ENV['FULL_REPROVISION'] || 'false').downcase == 'true',
  'loopback_gb' => Integer(ENV['LOOPBACK_GB'] || 4),
  'extra_packages' => (ENV['EXTRA_PACKAGES'] || '').split(','),
  'storage_policies' => (ENV['STORAGE_POLICIES'] || 'default').split(','),
  'ec_policy' => (ENV['EC_POLICY'] || ''),
  'servers_per_port' => Integer(ENV['SERVERS_PER_PORT'] || 0),
  'object_sync_method' => (ENV['OBJECT_SYNC_METHOD'] || 'rsync'),
  'post_as_copy' => (ENV['POST_AS_COPY'] || 'true').downcase == 'true',
  'part_power' => Integer(ENV['PART_POWER'] || 10),
  'replicas' => Integer(ENV['REPLICAS'] || 3),
  'ec_replicas' => Integer(ENV['EC_REPLICAS'] || 6),
  'regions' => Integer(ENV['REGIONS'] || 1),
  'zones' => Integer(ENV['ZONES'] || 4),
  'nodes' => Integer(ENV['NODES'] || 4),
  'disks' => Integer(ENV['DISKS'] || 4),
  'ec_disks' => Integer(ENV['EC_DISKS'] || 8),
  'keystone_auth_provision' => (ENV['KEYSTONE_AUTH_PROVISION'] || 'false').downcase == 'true',
  'swift_repo' => (ENV['SWIFT_REPO'] || 'git://github.com/openstack/swift.git'),
  'swift_repo_branch' => (ENV['SWIFT_REPO_BRANCH'] || 'master'),
  'swiftclient_repo' => (ENV['SWIFTCLIENT_REPO'] || 'git://github.com/openstack/python-swiftclient.git'),
  'swiftclient_repo_branch' => (ENV['SWIFTCLIENT_REPO_BRANCH'] || 'master'),
  'swift_bench_repo' => (ENV['SWIFTBENCH_REPO'] || 'git://github.com/openstack/swift-bench.git'),
  'swift_bench_repo_branch' => (ENV['SWIFTBENCH_REPO_BRANCH'] || 'master'),
  'swift_specs_repo' => (ENV['SWIFTSPECS_REPO'] || 'git://github.com/openstack/swift-specs.git'),
  'swift_specs_repo_branch' => (ENV['SWIFTSPECS_REPO_BRANCH'] || 'master'),
  'keystone_repo' => (ENV['KEYSTONE_REPO'] || 'git://github.com/openstack/keystone.git'),
  'keystone_repo_branch' => (ENV['KEYSTONE_REPO_BRANCH'] || 'master'),
  'keystonemiddleware_repo' => (ENV['KEYSTONEMIDDLEWARE_REPO'] || 'git://github.com/openstack/keystonemiddleware.git'),
  'keystonemiddleware_repo_branch' => (ENV['KEYSTONEMIDDLEWARE_REPO_BRANCH'] || 'master'),
  'openstackclient_repo' => (ENV['OPENSTACKCLIENT_REPO'] || 'git://github.com/openstack/python-openstackclient.git'),
  'openstackclient_repo_branch' => (ENV['OPENSTACKCLIENT_REPO_BRANCH'] || 'master'),
  'extra_key' => (ENV['EXTRA_KEY'] || ''),
  'source_root' => (ENV['SOURCE_ROOT'] || '/vagrant'),
}


Vagrant.configure('2') do |global_config|
  if Vagrant.has_plugin?('vagrant-proxyconf')
    global_config.proxy.http = ENV['HTTP_PROXY']
    global_config.proxy.https = ENV['HTTPS_PROXY']
  end
  global_config.ssh.forward_agent = true
  hosts.each do |vm_name, ip|
    global_config.vm.define vm_name do |config|
      hostname = vm_name
      if hostname == 'default' then
        hostname = (ENV['VAGRANT_HOSTNAME'] || 'saio')
      end
      config.vm.hostname = hostname
      config.vm.box = vagrant_box
      if vagrant_boxes.key? vagrant_box
        config.vm.box_url = vagrant_boxes[vagrant_box]
      end
      config.vm.network :private_network, ip: ip
      config.vm.provider :virtualbox do |vb|
        vb.name = "vagrant-#{hostname}-#{current_datetime}"
        vb.cpus = Integer(ENV['VAGRANT_CPUS'] || 1)
        vb.memory = Integer(ENV['VAGRANT_RAM'] || 1024)
        if (ENV['GUI'] || false)  # Why is my VM hung on boot? Find out!
          vb.gui = true
        end
      end

      if Vagrant.has_plugin?('vagrant-proxyconf')
        if global_config.proxy.http or global_config.proxy.https
          config.vm.provision 'shell', inline: <<-SHELL
            rm -vrf /var/lib/apt/lists/*
            apt-get update
            apt-get install -y git-core
            git config --global url.'https://'.insteadOf git://
          SHELL
        end
      end

      config.vm.provision :chef_solo do |chef|
        if local_config['keystone_auth_provision']
          chef.add_recipe 'keystone'
        end
        chef.add_recipe 'swift'
        chef.json = local_config
      end

      config.vm.provision 'shell', inline: <<-SHELL
	chown -R vagrant:vagrant #{local_config['source_root']} 
      SHELL

      if Vagrant.has_plugin?('vagrant-proxyconf')
        if global_config.proxy.http or global_config.proxy.https
          config.vm.provision 'shell', inline: <<-SHELL
            mv /etc/environment /etc/environment_bk
            mv /etc/profile.d/proxy.sh /home/vagrant/proxy_bk.sh
          SHELL
        end
      end

      if local_config['keystone_auth_provision']
        config.vm.provision 'shell', path: 'scripts/register_keystone_data.sh'
      end

    end
  end
end
