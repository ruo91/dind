#
# Dockerfile - Docker In Docker
#
# - Build
# docker build --rm -t dind .
#
# - Run
# docker run -d --name="dind" -h "dind" --privileged=true -v /dev:/dev dind
#
# - SSH
# ssh `docker inspect -f '{{ .NetworkSettings.IPAddress }}' dind`
#
# Use the base images
FROM ubuntu:14.04
MAINTAINER Yongbok Kim <ruo91@yongbok.net>

# Change the repository
RUN sed -i 's/archive.ubuntu.com/kr.archive.ubuntu.com/g' /etc/apt/sources.list

# The last update and install package for docker
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates lxc iptables apparmor \
 supervisor openssh-server curl git-core tmux nano

# Docker in Docker
RUN curl -sSL https://get.docker.com/ubuntu/ | sh
ADD conf/wrapdocker /usr/local/bin/wrapdocker

# Docker config
ENV DOCKER_CONF=/etc/default/docker
RUN chmod +x /usr/local/bin/wrapdocker \
 && sed -i '/^\#DOCKER_OPTS/ s:.*:DOCKER_OPTS=\"--dns 8.8.8.8 --dns 8.8.4.4 --dns-search google-public-dns-a.google.com\":' $DOCKER_CONF

# Supervisor
RUN mkdir -p /var/log/supervisor
ADD conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# SSH
RUN mkdir /var/run/sshd
RUN sed -i 's/without-password/yes/g' /etc/ssh/sshd_config
RUN sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
RUN sed -i 's/\#AuthorizedKeysFile/AuthorizedKeysFile/g' /etc/ssh/sshd_config

# Set the root password for ssh
RUN echo 'root:dind' |chpasswd

# Port
EXPOSE 22

# Daemon
CMD ["/usr/bin/supervisord"]