# rings

["object", "container", "account"].each_with_index do |service, p|
  execute "#{service}.builder-create" do
    command "sudo -u vagrant swift-ring-builder #{service}.builder create " \
      "#{node['part_power']} #{node['replicas']} 1"
    creates "/etc/swift/#{service}.builder"
    cwd "/etc/swift"
  end
  (1..node['disks']).each do |i|
    j = ((i - 1) % node['nodes']) + 1
    z = ((i - 1) % node['zones']) + 1
    r = ((z - 1) % node['regions']) + 1
    execute "#{service}.builder-add-sdb#{i}" do
      dsl = "r#{r}z#{z}-127.0.0.1:60#{j}#{p}/sdb#{i}"
      command "sudo -u vagrant swift-ring-builder #{service}.builder add " \
        "#{dsl} 1 && rm -f /etc/swift/#{service}.ring.gz || true"
      not_if "swift-ring-builder /etc/swift/#{service}.builder search #{dsl}"
      cwd "/etc/swift"
    end
  end
  execute "#{service}.builder-rebalance" do
    command "sudo -u vagrant swift-ring-builder #{service}.builder write_ring"
    not_if "sudo -u vagrant swift-ring-builder /etc/swift/#{service}.builder rebalance"
    creates "/etc/swift/#{service}.ring.gz"
    cwd "/etc/swift"
  end
end

node['storage_policies'].each_with_index do |name, p|
  service = "object-#{p + 1}"
  execute "#{service}.builder-create" do
    command "sudo -u vagrant swift-ring-builder #{service}.builder create " \
      "#{node['part_power']} #{node['replicas']} 1"
    creates "/etc/swift/#{service}.builder"
    cwd "/etc/swift"
  end
  (1..node['disks']).each do |i|
    j = ((i - 1) % node['nodes']) + 1
    z = ((i - 1) % node['zones']) + 1
    r = ((z - 1) % node['regions']) + 1
    execute "#{service}.builder-add-sdb#{i}" do
      command "sudo -u vagrant swift-ring-builder #{service}.builder add " \
        "r#{r}z#{z}-127.0.0.1:60#{j}0/sdb#{i} 1 && " \
        "rm -f /etc/swift/#{service}.ring.gz || true"
      not_if "swift-ring-builder /etc/swift/#{service}.builder search /sdb#{i}"
      cwd "/etc/swift"
    end
  end
  execute "#{service}.builder-rebalance" do
    command "sudo -u vagrant swift-ring-builder #{service}.builder write_ring"
    not_if "sudo -u vagrant swift-ring-builder /etc/swift/#{service}.builder rebalance"
    creates "/etc/swift/#{service}.ring.gz"
    cwd "/etc/swift"
  end
end

