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
  action :run
end

execute "python-swiftclient-install" do
  cwd "#{node['source_root']}/python-swiftclient"
  command "pip install -e . && pip install --ignore-installed -r test-requirements.txt"
  action :run
end

# since swiftclient forces cert reinstall; we do this now
# N.B. the saio_crt_path is coupled with "create cert" task in configs.rb
# yes, we create this file even if you have node['ssl'] == false
execute "fix certifi" do
  only_if { ::File.exist?(node['saio_crt_path']) }
  command "cat #{node['saio_crt_path']} >> $(python3 -m certifi)"
end

execute "swift-bench-install" do
  cwd "#{node['source_root']}/swift-bench"
  # swift-bench has an old version of hacking in the test requirements,
  # seems to pull back pbr to 0.11 and break everything; not installing
  # swift-bench's test-requirements is probably better than that
  command "pip install -e ."
  action :run
end

execute "python-swift-install" do
  cwd "#{node['source_root']}/swift"
  command "pip install -e .[kmip_keymaster] -r test-requirements.txt"
  action :run
end

# ignore this, apparently ohai doesn't support explicit python3
# https://github.com/chef/ohai/blob/main/lib/ohai/plugins/python.rb#L26
py3_ver_str = shell_out('python3 -c "import sys; print(sys.version)"').stdout
old_py3 = py3_ver_str.split[0].split('.')[1].to_i < 10

# ubuntu has a patched distutils that does egg-link/editable *installs* to
# /usr/local/lib/../site-packages; but won't look in that path unless
# VIRTUAL_ENV=1 (I mean who installs editable python packages as root!?)

# N.B. the "correct" answer on ubuntu is actually "dist-packages"
site_packages = shell_out('python3 -c "import site; print(site.getsitepackages()[0])"').stdout

# N.B. swift-bench has this same problem; but it goes away when the project
# grows a pyproject.toml
# 899958: add pyproject.toml to support pip 23.1 | https://review.opendev.org/c/openstack/swift/+/899958
execute "legacy-python-swift-install" do
  cwd "#{node['source_root']}/swift"
  command "sudo python3 setup.py develop --script-dir /usr/local/bin --install-dir=#{site_packages}"
  action :run
  only_if { old_py3 }
end

execute "install tox" do
  command "pip install tox"
  action :run
end

# extra source projects
[
  'swift-nvratelimit',
  'nvsts-middleware',
].each do |project_name|
  src_dir = "#{node['extra_source']}/#{project_name}"
  execute "install #{project_name}" do
    cwd src_dir
    command "pip install -e ."
    action :run
    only_if { ::File.directory?(src_dir) }
  end
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
