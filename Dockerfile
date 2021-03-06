# Dockerfile to build harden Ubuntu container images
# Based on Ubuntu
# Template https://docs.docker.com/examples/running_ssh_service/
# Origin: GITHUB https://github.com/HarisfazillahJamel/docker-ubuntu-14.04-harden
# Start : 26 Jan 2020

#
# Copyright (c) 2015-2020 Harisfazillah Jamel <linuxmalaysia@gmail.com>
#

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# This is my development scripts to harden server. Im using this docker to
# applied hardening scripts (hardening.sh). Use this Dockerfile and scripts related at your own risk.
# Harisfazillah Jamel - Kuala Lumpur - Malaysia - 25 Jan 2020

# Set the base image
FROM ubuntu:16.04

# File Author / Maintainer
MAINTAINER Harisfazillah Jamel linuxmalaysia <linuxmalaysia@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

### Start installation
### we are using Ubuntu packages called harden and harden-nids
### https://launchpad.net/ubuntu/+source/harden

# Hmm upstart issue
# https://github.com/docker/docker/issues/1024

RUN dpkg-divert --local --rename --add /sbin/initctl && \
    ln -sf /bin/true /sbin/initctl && \
    mkdir /var/run/sshd && \

    apt-get update && \

    apt-get install -y \
    ssh \
    ssh-client \
    openssh-server \
    fail2ban \
    git \
    wget \
    curl \
    pwgen \
    unbound \
    bash \
    sudo \
    software-properties-common \
    vim-tiny && \
    apt-add-repository -y ppa:ansible/ansible && \
    apt update && \
    apt install -y ansible && \
    apt upgrade -y && \
    apt autoremove -y && \
    apt clean && \


# setup ssh server

# SSH login fix. Otherwise user is kicked off after login

    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \

    echo "### End Of Installation"


### End installation

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile && \

    touch /var/log/auth.log && \
### error no user ####    chown syslog:adm /var/log/auth.log && \
    service fail2ban restart && \

# Add user1

    useradd user1 -m -s /bin/bash && \
    pwgen -N 1 > password.txt && \
    echo "user1:`cat password.txt`" | chpasswd && \
    usermod -a -G sudo user1 && \
    mkdir -p /home/user1/GITHUB && \
    chown user1:user1 /home/user1/GITHUB && \

    echo "########################################" && \
    echo " " && \
    echo "PASSWORD For user1 is `cat password.txt`" && \
    echo " " && \
    echo "example to run :- " && \
    echo "docker pull linuxmalaysia/docker-ubuntu-16.04-harden" && \
    echo "docker run --privileged=true -it -d -P --name my_ubuntu1 linuxmalaysia/docker-ubuntu-16.04-harden" && \
    echo " " && \
    echo "########################################" && \

# A GITHUB copy of linuxmalaysia/docker-ubuntu-16.04-harden

    cd /home/user1/GITHUB && \
    git clone https://github.com/linuxmalaysia/docker-ubuntu-16.04-harden.git && \
    cd && \
    pwd

# Hardening Initialization and Startup Script
ADD hardening.sh /hardening.sh
RUN chmod 755 /hardening.sh

# Expose the default port
EXPOSE 22

VOLUME ["/var/run/sshd"]

# Set default container command

CMD ["/bin/bash","/hardening.sh"]
CMD ["/usr/sbin/sshd", "-D"]
