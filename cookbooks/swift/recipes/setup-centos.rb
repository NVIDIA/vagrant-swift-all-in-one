# Install epel
package "epel-release" do
  action :install
end

execute "enable-extras" do
  command "yum-config-manager --enable epel extras"
  action :run
end

# if we want more versions of python in centos we need to build them from source

# packages
required_packages = [
  "openssl-devel", # libssl-dev is required for building wheels from the cryptography package in swift.
  "curl", "gcc", "memcached", "rsync", "sqlite", "xfsprogs", "git-core",
  "libffi-devel",  "libxml2-devel", "libxml2", "libxslt-devel", "zlib-devel", "autoconf", "libtool",
  "java-latest-openjdk", "haproxy", "python-devel", "python", "python3", "python3-devel", "docker_compose",
  "rclone",
]

if node['platform_version'] >= 8
  required_packages += [
    "rsync-daemon",
    "python2", "python2-devel",
    "python38", "python38-devel",
    "python39", "python39-devel"
  ]
else
  required_packages += [
    "python", "python-devel"
  ]
end

required_groupinstall_packages = ["Development Tools",]

# Group installs
required_groupinstall_packages.each do |grp|
  execute "group-install" do
    command "yum groupinstall -y \"" + grp + "\""
  end
end

extra_packages = node['extra_packages']
(required_packages + extra_packages).each do |pkg|
  package pkg do
    action :install
  end
end

# no-no packages (PIP is the bomb, system packages are OLD SKOOL)
unrequired_packages = []
unrequired_packages.each do |pkg|
  package pkg do
    action :purge
  end
end

if node['platform_version'] >= 8
  execute "update-alternatives-py39" do
    command "update-alternatives --set python3 /usr/bin/python3.9"
    default_env true
  end
  directory "/run/haproxy" do
    action :create
  end
else
  if node['use_python3']
    node.default['pip_url'] = "https://bootstrap.pypa.io/pip/3.6/get-pip.py"
  end
end

execute "source-profile" do
  command "echo 'source ~/.profile' >> ~#{node['username']}/.bashrc"
  not_if "grep 'source ~/.profile' ~#{node['username']}/.bashrc"
  action :run
  default_env true
end
