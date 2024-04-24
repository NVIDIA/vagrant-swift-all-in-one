#
#Copyright (c) 2015-2021, NVIDIA CORPORATION.
#SPDX-License-Identifier: Apache-2.0

include_recipe "swift::setup"
include_recipe "swift::statsd_exporter"
include_recipe "swift::source"
include_recipe "swift::data"
include_recipe "swift::configs"
include_recipe "swift::pykmip"
include_recipe "swift::rings"
include_recipe "swift::ansible"

# start main

execute "startmain" do
  command "swift-init start main"
  user node['username']
  group node["username"]
  default_env true
end
