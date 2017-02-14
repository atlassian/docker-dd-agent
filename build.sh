#!/bin/sh

set -eufx

download_if_not_cached() {
  filename="$1"
  url="$2"
  checksum="${3:-}"
  mkdir -p output
  if [ ! "`find 'output/' -maxdepth 1 -name "${filename}" -ctime -1`" ]; then
    wget -O "output/${filename}" --progress=dot:mega "${url}"
  fi
  if [ -n "${checksum}" ]; then
    echo "${checksum} output/${filename}" | sha256sum -c
  fi
}

cleanup() {
  rm -rf output
  rm -f unicreds
}

trap cleanup SIGINT SIGHUP SIGTERM

if [ ! -f '/.dockerenv' ]; then
  server_version=`docker version --format '{{.Server.APIVersion}}'`
  docker run --rm -t \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$(pwd):$(pwd)" \
    -w "$(pwd)" \
    -e "DOCKER_API_VERSION=${server_version}" \
    --entrypoint "$0" \
    docker.atlassian.io/buildeng/agent-baseagent \
    "$@"
  exit
fi

download_if_not_cached unicreds.tgz https://github.com/Versent/unicreds/releases/download/v1.5.0/unicreds_1.5.0_linux_x86_64.tgz 6380105ff9ea09927a5cd7bab82191eece7bbbf2b97b4b8965bcf1d95cf38f9b
tar --no-same-owner -zxvf output/unicreds.tgz
chmod +x unicreds

docker build --tag docker.atlassian.io/buildeng/dd-agent:http_checks .
cleanup

