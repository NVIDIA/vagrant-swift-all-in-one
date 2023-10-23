vagrant-swift-all-in-one
========================

A Swift-All-In-One in a few easy steps.

 1. `vagrant up`
 1. `vagrant ssh`
 1. `echo "awesome" > test`
 1. `swift upload test test`
 1. `swift download test test -o -`

This project assumes you have Virtualbox and Vagrant.

 * https://www.virtualbox.org/wiki/Downloads
 * http://www.vagrantup.com/downloads.html

running-tests
=============

You should be able to run most tests without too much fuss once SSH'ed into the
VM.

 1. `.unittests`
 1. `.functests`
 1. `.probetests`
 1. `vtox -e pep8`
 1. `vtox -e py27`
 1. `vtox  # run all gate checks`

localrc-template
================

A few things are configurable, see `localrc-template`.

 1. `cp localrc-template localrc`
 1. `vi localrc`
 1. `source localrc`
 1. `vagrant provision`
 1. `vagrant ssh`
 1. `rebuildswift`


s3cmd
=====

You know you want to play with s3api, we got you covered.

```
vagrant ssh
s3cmd mb s3://s3test
s3cmd ls
```

Request Tracing
===============
You can enable request tracing by:
```
export TRACING=true
```

When tracing has been enabled a Jaeger all-in-one will be started in the
vagrant environment. It was started with the bin/reset_jaeger tool.  You can
view all your traces at: http://saio:16686/search

The reset_jaeger.sh script basically runs:

```
docker run -d --name jaeger \\
-e COLLECTOR_ZIPKIN_HOST_PORT=:9411 \\
-p 5775:5775/udp \\
-p 6831:6831/udp \\
-p 6832:6832/udp \\
-p 5778:5778 \\
-p 16686:16686 \\
-p 14268:14268 \\
-p 14250:14250 \\
-p 9411:9411 \\
jaegertracing/all-in-one:1.27
```

See: https://www.jaegertracing.io/docs/1.27/getting-started/

If you want to reset and clear the traces just run:
```
reset_jaeger.sh
```

NOTE: We should go via OTel collector, but I havn't implemented that yet. But there are some notes on that below

For the OTel collector we should be able to run something like:
```
docker pull otel/opentelemetry-collector:latest
docker run -d otel/opentelemetry-collector:latest
```
See: https://opentelemetry.io/docs/collector/getting-started/

NOTE: of course you can also specify a version. We should probably pick whatever we use for prod (when we get that far)

If you want to have a custom config, volume mount in a config:
```
docker run -v $(pwd)/config.yaml:/etc/otelcol/config.yaml otel/opentelemetry-collector
```

ninja-dev-tricks
================

You should add the configured `IP` from your localrc to your `/etc/hosts` or use the default:

```
sudo bash -c 'echo "192.168.8.80    saio" >> /etc/hosts'
```

Then you can easily share snippets that talk to network services running in your Swift-All-In-One from your host!

```
curl -s http://saio:8080/info | python -m json.tool
```

A few scripts are available to make your dev life easier.

 1. `vagrant up --provision` will bring up your VM in working order (useful
    when your VM is halted)
 1. `source localrc; vagrant provision` on your host to push the new Chef bits
    in place (useful if you change localrc)
 1. `rebuildswift` to reapply everything like it would be at the end of Chef
    time (useful to revert local config changes)
 1. `resetswift` will wipe the drives and leave any local config changes in
    place (useful just to clean out Swift data)
 1. `reinstallswift` will make sure all of the bin scripts are installed
    correctly and restart the main swift processes (useful if you change
    branches)
 1. `autodoc [swift|swiftclient]` will build the sphinx docs and
    watch files for changes, and upload them to a public container on your vm
    so you can review them as you edit
 1. `vtox` will hack the local tox.ini and setup.py so you can run tox tests
    successfully on the swift repo in the `/vagrant` directory
 1. `reec` will rebuild/reinstall all the liberasure/pyeclib[/isa-l] bits!
 1. `venv py37` will make sure your tox virtualenv is ready and let you py3
