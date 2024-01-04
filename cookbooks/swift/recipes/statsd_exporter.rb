STATSD_EXPORTER_VERSION="0.24.0"
PROMETHEUS_VERSION="2.47.0"
#GRAFANA_VERSION="10.1.1"

USER_HOME = "/home/#{node['username']}"

STATSD_EXPORTER_DIRNAME = "statsd_exporter-#{STATSD_EXPORTER_VERSION}.linux-#{node['arch']}"
execute "download statsd_exporter" do
  cwd USER_HOME
  command "curl --fail -OL https://github.com/prometheus/statsd_exporter/releases/download/v#{STATSD_EXPORTER_VERSION}/#{STATSD_EXPORTER_DIRNAME}.tar.gz"
  creates "#{STATSD_EXPORTER_DIRNAME}.tar.gz"
  action :run
end
execute "unpack statsd_exporter" do
  cwd USER_HOME
  command "tar xzf #{STATSD_EXPORTER_DIRNAME}.tar.gz"
  creates STATSD_EXPORTER_DIRNAME
  action :run
end
execute "install statsd_exporter" do
    command "cp #{USER_HOME}/#{STATSD_EXPORTER_DIRNAME}/statsd_exporter /usr/local/bin/statsd_exporter"
    creates "/usr/local/bin/statsd_exporter"
    action :run
end
    
PROMETHEUS_DIRNAME = "prometheus-#{PROMETHEUS_VERSION}.linux-#{node['arch']}"
execute "download prometheus" do
  cwd USER_HOME
  command "curl --fail -OL https://github.com/prometheus/prometheus/releases/download/v#{PROMETHEUS_VERSION}/#{PROMETHEUS_DIRNAME}.tar.gz"
  creates "#{PROMETHEUS_DIRNAME}.tar.gz"
  action :run
end
execute "unpack prometheus" do
  cwd USER_HOME
  command "tar xzf #{PROMETHEUS_DIRNAME}.tar.gz"
  creates PROMETHEUS_DIRNAME
  action :run
end
execute "install prometheus" do
  command "cp #{USER_HOME}/#{PROMETHEUS_DIRNAME}/prometheus /usr/local/bin/prometheus"
  creates "/usr/local/bin/prometheus"
  action :run
end

[
  "prometheus.service",
  "statsd_exporter@.service",
].each do |filename|
  cookbook_file "/etc/systemd/system/#{filename}" do
    source "etc/systemd/system/#{filename}"
  end
end

# TODO: do similar for grafana?
#curl -OL https://dl.grafana.com/oss/release/grafana_#{GRAFANA_VERSION}_#{node['arch']}.deb
#sudo dpkg -i grafana_*.deb
