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


# ensure source_root

directory "#{node['source_root']}" do
  owner "vagrant"
  group "vagrant"
  action :create
end

# python install

execute "git python-swiftclient" do
  cwd "#{node['source_root']}"
  command "sudo -u vagrant git clone -b #{node['swiftclient_repo_branch']} #{node['swiftclient_repo']}"
  creates "#{node['source_root']}/python-swiftclient"
  action :run
end

execute "git swift-bench" do
  cwd "#{node['source_root']}"
  command "sudo -u vagrant git clone -b #{node['swift_bench_repo_branch']} #{node['swift_bench_repo']}"
  creates "#{node['source_root']}/swift-bench"
  action :run
end

execute "git swift" do
  cwd "#{node['source_root']}"
  command "sudo -u vagrant git clone -b #{node['swift_repo_branch']} #{node['swift_repo']}"
  creates "#{node['source_root']}/swift"
  action :run
end

execute "git swift-specs" do
  cwd "#{node['source_root']}"
  command "sudo -u vagrant git clone -b #{node['swift_specs_repo_branch']} #{node['swift_specs_repo']}"
  creates "#{node['source_root']}/swift-specs"
  action :run
end

execute "fix semantic_version error from testtools" do
  command "pip install --upgrade testtools"
end

execute "python-swiftclient-install" do
  cwd "#{node['source_root']}/python-swiftclient"
  command "pip install -e . && pip install -r test-requirements.txt"
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
  command "pip install -e . && pip install -r test-requirements.txt"
  if not node['full_reprovision']
    creates "/usr/local/lib/python2.7/dist-packages/swift.egg-link"
  end
  action :run
end

execute "swift-specs-install" do
  cwd "#{node['source_root']}/swift-specs"
  command "pip install -r requirements.txt"
  action :run
end

execute "install tox" do
  command "pip install tox"
  if not node['full_reprovision']
    creates "/usr/local/lib/python2.7/dist-packages/tox"
  end
  action :run
end

[
  'swift',
  'python-swiftclient',
].each do |dirname|
  execute "ln #{dirname}" do
    command "ln -s #{node['source_root']}/#{dirname} /home/vagrant/#{dirname}"
    creates "/home/vagrant/#{dirname}"
  end
end

if node['keystone_auth_provision'] then
  execute "git keystonemiddleware" do
    cwd "/vagrant"
    command "git clone -b #{node['keystonemiddleware_repo_branch']} #{node['keystonemiddleware_repo']}"
    creates "/vagrant/keystonemiddleware"
    action :run
  end

  execute "keystonemiddleware-install" do
    cwd "/vagrant/keystonemiddleware"
    if not node['full_reprovision']
      creates "/usr/local/lib/python2.7/dist-packages/keystonemiddleware.egg-link"
    end
    command "pip install -e . && pip install -r test-requirements.txt"
    action :run
  end
end
