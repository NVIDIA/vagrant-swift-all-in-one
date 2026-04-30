#
# SPDX-FileCopyrightText: Copyright (c) 2015-2026 NVIDIA CORPORATION All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

STATSD_EXPORTER_VERSION="0.26.0"
PROMETHEUS_VERSION="2.48.1"
#GRAFANA_VERSION="10.1.1"
ARCH=node.arm? ? "arm64" : "amd64"

USER_HOME = "/home/#{node['username']}"

STATSD_EXPORTER_DIRNAME = "statsd_exporter-#{STATSD_EXPORTER_VERSION}.linux-#{ARCH}"
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

PROMETHEUS_DIRNAME = "prometheus-#{PROMETHEUS_VERSION}.linux-#{ARCH}"
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
