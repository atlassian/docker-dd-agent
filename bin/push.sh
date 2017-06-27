#!/bin/bash

docker load -i image.tar
docker push docker.atlassian.io/buildeng/dd-agent-http-checks
