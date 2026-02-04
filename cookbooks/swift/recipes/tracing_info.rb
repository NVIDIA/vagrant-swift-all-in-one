#
#Copyright (c) 2015-2022, NVIDIA CORPORATION.
#SPDX-License-Identifier: Apache-2.0

execute "Start jaeger all-in-one docker image" do
  command "/vagrant/bin/reset_jaeger.sh"
end

log 'show jaeger docker info' do
  message %(
  A Jaeger all-in-one has been started in the vagrant environment. It was started with the bin/reset_jaeger tool.
  You can view all your traces at: http://saio:16686/search

  If you want to reset and clear the traces just run:

    reset_jaeger.sh
  )
end
