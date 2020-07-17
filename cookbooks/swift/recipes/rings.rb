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


# rings

["container", "account"].each_with_index do |service, p|
  execute "#{service}.builder-create" do
    command "swift-ring-builder #{service}.builder create " \
      "#{node['part_power']} #{node['replicas']} 1"
    user node['username']
    group node["username"]
    creates "/etc/swift/#{service}.builder"
    cwd "/etc/swift"
  end
  (1..node['disks']).each do |i|
    n_idx = ((i - 1) % node['nodes']) + 1
    z = ((i - 1) % node['zones']) + 1
    r = ((z - 1) % node['regions']) + 1
    dev = "sdb#{i}"
    ip = "127.0.0.#{i}"
    port = "60#{n_idx}#{p + 1}"
    replication_port = "60#{n_idx + 4}#{p + 1}"
    dsl = "r#{r}z#{z}-#{ip}:#{port}/#{dev}"
    if node['replication_servers'] then
      dsl = "r#{r}z#{z}-#{ip}:#{port}R#{ip}:#{replication_port}/#{dev}"
    end
    execute "#{service}.builder-add-#{dev}" do
      command "swift-ring-builder #{service}.builder add " \
        "#{dsl} 1 && rm -f /etc/swift/#{service}.ring.gz || true"
      user node['username']
      group node["username"]
      not_if "swift-ring-builder /etc/swift/#{service}.builder search #{dsl}"
      cwd "/etc/swift"
    end
  end
  execute "#{service}.builder-rebalance" do
    command "swift-ring-builder /etc/swift/#{service}.builder rebalance -f"
    user node['username']
    group node["username"]
    cwd "/etc/swift"
  end
end

node['storage_policies'].each_with_index do |name, p|
  service = "object"
  if p >= 1 then
    service += "-#{p}"
  end
  if name == node['ec_policy'] then
    replicas = node['ec_replicas'] * node['ec_duplication']
    num_disks = node['ec_disks']
  else
    replicas = node['replicas']
    num_disks = node['disks']
  end
  execute "#{service}.builder-create" do
    command "swift-ring-builder #{service}.builder create " \
      "#{node['part_power']} #{replicas} 1"
    user node['username']
    group node["username"]
    creates "/etc/swift/#{service}.builder"
    cwd "/etc/swift"
  end
  (1..num_disks).each do |i|
    n_idx = ((i - 1) % node['nodes']) + 1
    z = ((i - 1) % node['zones']) + 1
    r = ((z - 1) % node['regions']) + 1
    dev = "sdb#{i}"
    ip = "127.0.0.#{n_idx}"
    port = "60#{n_idx}0"
    replication_port = "60#{n_idx + 4}0"
    if node['servers_per_port'] > 0 then
      # Range ports per disk per node from 60j6 - 60j9
      # NOTE: this only supports DISKS <= 4 * NODES
      p = 5 + (i / Float(node['nodes'])).ceil.to_int
      port = "60#{n_idx}#{p}"
      replication_port = "60#{n_idx + 4}#{p}"
    end
    dsl = "r#{r}z#{z}-#{ip}:#{port}/#{dev}"
    if node['replication_servers'] then
      dsl = "r#{r}z#{z}-#{ip}:#{port}R#{ip}:#{replication_port}/#{dev}"
    end
    execute "#{service}.builder-add-#{dev}" do
      command "swift-ring-builder #{service}.builder add " \
        "#{dsl} 1 && rm -f /etc/swift/#{service}.ring.gz || true"
      user node['username']
      group node["username"]
      not_if "swift-ring-builder /etc/swift/#{service}.builder search /#{dsl}"
      cwd "/etc/swift"
    end
  end
  execute "#{service}.builder-rebalance" do
    command "swift-ring-builder /etc/swift/#{service}.builder rebalance -f"
    user node['username']
    group node["username"]
    cwd "/etc/swift"
  end
end
