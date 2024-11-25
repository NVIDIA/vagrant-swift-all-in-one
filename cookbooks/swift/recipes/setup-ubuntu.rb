# deadsnakes for all the pythons
package "software-properties-common" do
  action :install
  not_if "which add-apt-repository"
end

execute "deadsnakes key" do
  command "sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys"
  action :run
  not_if "sudo apt-key list | grep 'Launchpad PPA for deadsnakes'"
end

execute "add repo" do
  command "sudo add-apt-repository ppa:deadsnakes/ppa"
end

# backports seems to be enabled on xenial already?
execute "enable backports" do
  command "sudo sed -ie 's/# deb http:\\/\\/archive.ubuntu.com\\/ubuntu trusty-backports/deb http:\\/\\/archive.ubuntu.com\\/ubuntu trusty-backports/' /etc/apt/sources.list"
  action :run
  not_if "sudo grep -q '^deb .* trusty-backports' /etc/apt/sources.list"
end

execute "apt-get-update" do
  command "apt-get update && touch /tmp/.apt-get-update"
  if not node['full_reprovision']
    creates "/tmp/.apt-get-update"
  end
  action :run
end

systemd_unit "multipathd" do
  # focal boxes generate a lot of useless logs with this guy running
  action [:disable, :stop]
end

# packages
required_packages = [
  "libssl-dev", # libssl-dev is required for building wheels from the cryptography package in swift.
  "curl", "gcc", "memcached", "rsync", "sqlite3", "xfsprogs", "git-core", "build-essential",
  "libffi-dev",  "libxml2-dev", "libxml2", "libxslt1-dev", "zlib1g-dev", "autoconf", "libtool",
  "openjdk-11-jre-headless", "haproxy", "docker_compose", "rclone",
]

if node['platform_version'] == '22.04'
  required_packages += [
    "python2-dev", "python2", "python3", "python3-dev",
    "python3.7", "python3.7-dev", "python3.7-distutils",
    "python3.8", "python3.8-dev", "python3.8-distutils",
    "python3.9", "python3.9-dev", "python3.9-distutils",
  ]
else
  required_packages += [
    "python-dev",
    "python3.6", "python3.6-dev", "python3.7", "python3.7-dev",
    "python3.8", "python3.8-dev",
  ]
end

extra_packages = node['extra_packages']
(required_packages + extra_packages).each do |pkg|
  package pkg do
    action :install
  end
end

# no-no packages (PIP is the bomb, system packages are OLD SKOOL)
unrequired_packages = [
  "python-requests",  "python-six", "python-urllib3",
  "python-pbr", "python-pip",
  "python3-requests",  "python3-six", "python3-urllib3",
  "python3-pbr", "python3-pip",
]
unrequired_packages.each do |pkg|
  package pkg do
    action :purge
  end
end
