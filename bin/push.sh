#!/bin/bash

gunzip image.tar.gz | docker load
docker push docker.atlassian.io/buildeng/dd-agent-http-checks
