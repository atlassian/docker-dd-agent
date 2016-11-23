#!/bin/bash
#set -e

AWS_REGION="${AWS_REGION:=us-east-1}"
DD_API_KEY=$(/buildeng/unicreds -r $AWS_REGION get datadog_api_key | head -c -1)

if [[ $DD_API_KEY ]]; then
  export API_KEY=${DD_API_KEY}
fi

if [[ $API_KEY ]]; then
	sed -i -e "s/^.*api_key:.*$/api_key: ${API_KEY}/" /etc/dd-agent/datadog.conf
else
	echo "You must set API_KEY environment variable to run the DogStatsD container"
	exit 1
fi

if [[ $DD_URL ]]; then
    sed -i -e 's@^.*dd_url:.*$@dd_url: '${DD_URL}'@' /etc/dd-agent/datadog.conf
fi

export PATH="/opt/datadog-agent/embedded/bin:/opt/datadog-agent/bin:$PATH"

exec "$@"
