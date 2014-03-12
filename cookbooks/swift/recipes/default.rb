include_recipe "swift::setup"
include_recipe "swift::source"
include_recipe "swift::data"
include_recipe "swift::configs"
include_recipe "swift::rings"

# start main

execute "startmain" do
  command "sudo -u vagrant swift-init start main"
end

