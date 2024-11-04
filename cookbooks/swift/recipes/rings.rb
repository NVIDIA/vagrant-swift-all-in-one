#
#Copyright (c) 2015-2021, NVIDIA CORPORATION.
#SPDX-License-Identifier: Apache-2.0

# rings

["container", "account"].each_with_index do |service, p|
  execute "#{service}.builder-create" do
    command "swift-ring-builder #{service}.builder create " \
      "#{node['part_power']} #{node['replicas']} 1"
    user node['username']
    group node["username"]
    creates "/etc/swift/#{service}.builder"
    cwd "/etc/swift"
    default_env true
  end
  (1..node['disks']).each do |i|
    n_idx = ((i - 1) % node['nodes']) + 1
    z = ((n_idx - 1) % node['zones']) + 1
    r = ((z - 1) % node['regions']) + 1
    dev = "sdb#{i}"
    ip = "127.0.0.#{n_idx}"
    port = 6000 + 10 * n_idx + (p + 1)
    replication_port = 6000 + 10 * (n_idx + node['nodes']) + (p + 1)
    dsl = "r#{r}z#{z}-#{ip}:#{port}/#{dev}"
    if node['replication_servers'] then
      dsl = "r#{r}z#{z}-#{ip}:#{port}R#{ip}:#{replication_port}/#{dev}"
    end
    execute "#{service}.builder-add-#{dev}" do
      command "swift-ring-builder #{service}.builder add " \
        "#{dsl} 1 && rm -f /etc/swift/#{service}.ring.gz || true"
      user node['username']
      group node["username"]
      default_env true
      not_if "/usr/local/bin/swift-ring-builder /etc/swift/#{service}.builder search #{dsl}"
      cwd "/etc/swift"
    end
  end
  execute "#{service}.builder-rebalance" do
    command "swift-ring-builder /etc/swift/#{service}.builder rebalance -f"
    user node['username']
    group node["username"]
    cwd "/etc/swift"
    returns [0, 1]  # Allow EXIT_WARNING
    default_env true
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
    default_env true
  end
  (1..num_disks).each do |i|
    n_idx = ((i - 1) % node['nodes']) + 1
    z = ((n_idx - 1) % node['zones']) + 1
    r = ((z - 1) % node['regions']) + 1
    dev = "sdb#{i}"
    ip = "127.0.0.#{n_idx}"
    port = 6000 + 10 * n_idx
    replication_port = 6000 + 10 * (n_idx + node['nodes'])
    if node['servers_per_port'] > 0 then
      # Range ports per disk per node from 60j6 - 60j9
      # NOTE: this only supports DISKS <= 4 * NODES
      p = 5 + (i / Float(node['nodes'])).ceil.to_int
      port = 6000 + 10 * n_idx + p
      replication_port = 6000 + 10 * (n_idx + node['nodes']) + p
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
      not_if "/usr/local/bin/swift-ring-builder /etc/swift/#{service}.builder search /#{dsl}"
      cwd "/etc/swift"
      default_env true
    end
  end
  execute "#{service}.builder-rebalance" do
    command "swift-ring-builder /etc/swift/#{service}.builder rebalance -f"
    user node['username']
    group node["username"]
    cwd "/etc/swift"
    returns [0, 1]  # Allow EXIT_WARNING
    default_env true
  end
end
