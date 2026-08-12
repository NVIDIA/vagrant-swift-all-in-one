#!/bin/bash
docker_id=$(docker ps |grep jaeger  |awk '{print $1}')

if [ -n "$docker_id" ]; then
  docker stop $docker_id
  docker rm $docker_id
fi

# 1.35 is the first release that ingests OTLP natively, which is what
# Swift's supported exporter speaks; 4317 is gRPC, 4318 HTTP.
docker run -d --name jaeger \
	-e COLLECTOR_ZIPKIN_HOST_PORT=:9411 \
	-e COLLECTOR_OTLP_ENABLED=true \
	-p 5778:5778 \
	-p 16686:16686 -p 14268:14268 -p 14250:14250 -p 9411:9411 \
	-p 4317:4317 -p 4318:4318 \
	jaegertracing/all-in-one:1.57
