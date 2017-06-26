#!/bin/bash

docker save docker.atlassian.io/buildeng/dd-agent-http-checks | gzip > image.tar.gz
