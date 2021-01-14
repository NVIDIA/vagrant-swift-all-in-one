#
#Copyright (c) 2015-2021, NVIDIA CORPORATION.
#SPDX-License-Identifier: Apache-2.0

if not node['kmip'] then
  # TODO: more cleanup?
  service 'pykmip-server' do
    action [:disable, :stop]
  end
  return
end

PYKMIP_DIR = "/etc/pykmip"


[
  PYKMIP_DIR,
  "#{PYKMIP_DIR}/certs",
  "#{PYKMIP_DIR}/policies",
  "/var/lib/pykmip",
  "/var/log/pykmip",
].each do |dir|
  directory dir do
    owner node['username']
    group node["username"]
    action :create
  end
end


# keys and certs

CA_KEY = "#{PYKMIP_DIR}/certs/ca.key"
execute "create certificate authority key" do
  cwd PYKMIP_DIR
  user node['username']
  group node["username"]
  # creates CA_KEY
  command "openssl genrsa -out #{CA_KEY} 2048"
end

CA_CRT = "#{PYKMIP_DIR}/certs/ca.crt"
execute "create self-signed certificate authority crt" do
  cwd PYKMIP_DIR
  user node['username']
  group node["username"]
  # creates CA_CRT
  command "openssl req -new -x509 -key #{CA_KEY} -days 3650 " \
    "-out #{CA_CRT} -subj '/CN=ca.example.com'"
end

SERVER_KEY = "#{PYKMIP_DIR}/certs/kmip-server.key"
execute "create pykmip server key" do
  cwd PYKMIP_DIR
  user node['username']
  group node["username"]
  # creates SERVER_KEY
  command "openssl genrsa -out #{SERVER_KEY} 2048"
end

SERVER_CSR = "#{PYKMIP_DIR}/certs/kmip-server.csr"
execute "create pykmip server csr" do
  cwd PYKMIP_DIR
  user node['username']
  group node["username"]
  # creates SERVER_CSR
  command "openssl req -new -key #{SERVER_KEY} " \
    "-out #{SERVER_CSR} -subj '/CN=kmip-server.example.com'"
end

SERVER_CRT = "#{PYKMIP_DIR}/certs/kmip-server.crt"
execute "creates pykmip server crt" do
  cwd PYKMIP_DIR
  user node['username']
  group node["username"]
  # creates SERVER_CRT
  command "openssl x509 -req -CA #{CA_CRT} -CAkey #{CA_KEY} -CAcreateserial " \
    "-in #{SERVER_CSR} -out #{SERVER_CRT} -days 3650"
end

CLIENT_KEY = "#{PYKMIP_DIR}/certs/kmip-client.key"
execute "create pykmip client key" do
  cwd PYKMIP_DIR
  user node['username']
  group node["username"]
  # creates CLIENT_KEY
  command "openssl genrsa -out #{CLIENT_KEY} 2048"
end

CLIENT_CSR = "#{PYKMIP_DIR}/certs/kmip-client.csr"
execute "create pykmip client csr" do
  cwd PYKMIP_DIR
  user node['username']
  group node["username"]
  # creates CLIENT_CSR
  command "openssl req -new -key #{CLIENT_KEY} " \
    "-out #{CLIENT_CSR} -subj '/CN=kmip-client.example.com'"
end

CLIENT_CRT = "#{PYKMIP_DIR}/certs/kmip-client.crt"
execute "creates pykmip client crt" do
  cwd PYKMIP_DIR
  user node['username']
  group node["username"]
  # creates CLIENT_CRT
  command "openssl x509 -req -CA #{CA_CRT} -CAkey #{CA_KEY} -CAcreateserial " \
    "-in #{CLIENT_CSR} -out #{CLIENT_CRT} -days 3650"
end


# trust ca

execute "install ca" do
  command "cp #{CA_CRT} /usr/local/share/ca-certificates/ca.crt"
end

execute "trust ca" do
  command "sudo update-ca-certificates"
end


# configs

template "#{PYKMIP_DIR}/server.conf" do
  source "etc/pykmip/server.conf.erb"
  owner node["username"]
  group node["username"]
  variables({
    :ca_crt => CA_CRT,
    :server_key => SERVER_KEY,
    :server_crt => SERVER_CRT,
  })
end

template "#{PYKMIP_DIR}/pykmip.conf" do
  source "etc/pykmip/pykmip.conf.erb"
  owner node["username"]
  group node["username"]
  variables({
    :ca_crt => CA_CRT,
    :client_key => CLIENT_KEY,
    :client_crt => CLIENT_CRT,
  })
end

template "/etc/swift/kmip_keymaster.conf" do
  source "etc/swift/kmip_keymaster.conf.erb"
  owner node["username"]
  group node["username"]
  variables({
    :client_key => CLIENT_KEY,
    :client_crt => CLIENT_CRT,
    :ca_crt => CA_CRT,
  })
end


# install

execute "install pykmip" do
  command "pip install pykmip --upgrade"
  if not node['full_reprovision']
    creates "/usr/local/bin/pykmip-server"
  end
end


# systemd unit file

cookbook_file "/etc/systemd/system/pykmip-server.service" do
  source "etc/systemd/system/pykmip-server.service"
end

service 'pykmip-server' do
  action [:enable, :restart, :start]
end


# add key

execute "add key" do
  command "/vagrant/bin/kmipkey"
end
