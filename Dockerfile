FROM debian:jessie

MAINTAINER Datadog <package@datadoghq.com>

ENV DOCKER_DD_AGENT=yes \
    AGENT_VERSION=1:5.16.0-1 \
    DD_ETC_ROOT=/etc/dd-agent \
    PATH="/opt/datadog-agent/embedded/bin:/opt/datadog-agent/bin:${PATH}" \
    PYTHONPATH=/opt/datadog-agent/agent \
    DD_CONF_LOG_TO_SYSLOG=no \
    NON_LOCAL_TRAFFIC=yes \
    DD_SUPERVISOR_DELETE_USER=yes

# Install the Agent
RUN echo "deb http://apt.datadoghq.com/ stable main" > /etc/apt/sources.list.d/datadog.list \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C7A7DA52 \
 && apt-get update \
 && apt-get install --no-install-recommends -y datadog-agent="${AGENT_VERSION}" \
    ca-certificates \
    python-pip \
    python-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure the Agent
# 1. Remove dd-agent user from init.d configuration
# 2. Fix permission on /etc/init.d/datadog-agent
RUN mv ${DD_ETC_ROOT}/datadog.conf.example ${DD_ETC_ROOT}/datadog.conf \
 && sed -i 's/AGENTUSER="dd-agent"/AGENTUSER="root"/g' /etc/init.d/datadog-agent \
 && rm -f ${DD_ETC_ROOT}/conf.d/network.yaml.default \
 && chmod +x /etc/init.d/datadog-agent

# Add Docker check
COPY conf.d/docker_daemon.yaml ${DD_ETC_ROOT}/conf.d/docker_daemon.yaml
# Add install and config files

# Add unicreds
COPY unicreds /buildeng/unicreds

COPY entrypoint.sh /entrypoint.sh
COPY config_builder.py /config_builder.py

# Custom configuration
COPY custom_config /custom_config
COPY custom_templates /custom_templates
RUN mkdir /custom_generated
COPY generate_conf.py /
COPY requirements.txt /
RUN pip install -r requirements.txt

# Extra conf.d and checks.d
VOLUME ["/conf.d", "/checks.d"]

# Expose DogStatsD, supervisord and trace-agent ports
EXPOSE 8125/udp 9001/tcp 8126/tcp

# Healthcheck
HEALTHCHECK --interval=5m --timeout=3s --retries=1 \
  CMD test $(/opt/datadog-agent/embedded/bin/python /opt/datadog-agent/bin/supervisorctl \
      -c /etc/dd-agent/supervisor.conf status | awk '{print $2}' | egrep -v 'RUNNING|EXITED' | wc -l) \
      -eq 0 || exit 1

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/dd-agent/supervisor.conf"]
