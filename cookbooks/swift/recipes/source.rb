#
#Copyright (c) 2015-2021, NVIDIA CORPORATION.
#SPDX-License-Identifier: Apache-2.0

# ensure source_root

directory "#{node['source_root']}" do
  owner node["username"]
  group node["username"]
  action :create
end

# python install

execute "git python-swiftclient" do
  cwd "#{node['source_root']}"
  command "git clone -b #{node['swiftclient_repo_branch']} #{node['swiftclient_repo']}"
  user node['username']
  group node["username"]
  creates "#{node['source_root']}/python-swiftclient"
  action :run
end

execute "git swift-bench" do
  cwd "#{node['source_root']}"
  command "git clone -b #{node['swift_bench_repo_branch']} #{node['swift_bench_repo']}"
  user node['username']
  group node["username"]
  creates "#{node['source_root']}/swift-bench"
  action :run
end

execute "git swift" do
  cwd "#{node['source_root']}"
  command "git clone -b #{node['swift_repo_branch']} #{node['swift_repo']}"
  user node['username']
  group node["username"]
  creates "#{node['source_root']}/swift"
  action :run
end

execute "git liberasurecode" do
  cwd "#{node['source_root']}"
  command "git clone -b #{node['liberasurecode_repo_branch']} #{node['liberasurecode_repo']}"
  user node['username']
  group node["username"]
  creates "#{node['source_root']}/liberasurecode"
  action :run
end

execute "git pyeclib" do
  cwd "#{node['source_root']}"
  command "git clone -b #{node['pyeclib_repo_branch']} #{node['pyeclib_repo']}"
  user node['username']
  group node["username"]
  creates "#{node['source_root']}/pyeclib"
  action :run
end


execute "fix semantic_version error from testtools" do
  command "pip install --upgrade testtools"
end

execute "liberasurecode-install" do
  cwd "#{node['source_root']}/liberasurecode"
  command "./autogen.sh && " \
    "./configure && " \
    "make && " \
    "make install && " \
    "ldconfig"
  if not node['full_reprovision']
    creates "/usr/local/lib/liberasurecode.so.1.2.0"
  end
  # avoid /opt/chef/embedded/bin - related to chef/chef-dk#313
  environment 'PATH' => "/usr/bin:#{ENV['PATH']}"
  action :run
end

execute "python-pyeclib-install" do
  cwd "#{node['source_root']}/pyeclib"
  command "pip install -e . && pip install -r test-requirements.txt"
  if not node['full_reprovision']
    creates "/usr/local/lib/python2.7/dist-packages/pyeclib.egg-link"
  end
  action :run
end

execute "python-swiftclient-install" do
  cwd "#{node['source_root']}/python-swiftclient"
  command "pip install -e . && pip install --ignore-installed -r test-requirements.txt"
  if not node['full_reprovision']
    creates "/usr/local/lib/python2.7/dist-packages/python-swiftclient.egg-link"
  end
  action :run
end

execute "swift-bench-install" do
  cwd "#{node['source_root']}/swift-bench"
  # swift-bench has an old version of hacking in the test requirements,
  # seems to pull back pbr to 0.11 and break everything; not installing
  # swift-bench's test-requirements is probably better than that
  command "pip install -e ."
  if not node['full_reprovision']
    creates "/usr/local/lib/python2.7/dist-packages/swift-bench.egg-link"
  end
  action :run
end

execute "python-swift-install" do
  cwd "#{node['source_root']}/swift"
  command "pip install 'sqlalchemy<2.0.0' -e .[kmip_keymaster] && pip install -r test-requirements.txt"
  if not node['full_reprovision']
    creates "/usr/local/lib/python2.7/dist-packages/swift.egg-link"
  end
  action :run
end

execute "install tox" do
  command "pip install tox"
  if not node['full_reprovision']
    creates "/usr/local/lib/python2.7/dist-packages/tox"
  end
  action :run
end

# add some helpful symlinks

[
  'swift',
  'python-swiftclient',
].each do |dirname|
  execute "ln #{dirname}" do
    command "ln -s #{node['source_root']}/#{dirname} /home/#{node['username']}/#{dirname}"
    creates "/home/#{node['username']}/#{dirname}"
  end
end
