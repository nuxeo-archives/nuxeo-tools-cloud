# test deployment target
#
# VERSION               0.0.1

FROM       phusion/baseimage:0.9.18
MAINTAINER Nuxeo Packagers <packagers@nuxeo.com>

RUN echo "deb http://netboot.in.nuxeo.com/ubuntu/ trusty main restricted universe multiverse" > /etc/apt/sources.list
RUN echo "deb http://netboot.in.nuxeo.com/ubuntu/ trusty-updates main restricted universe multiverse" >> /etc/apt/sources.list
RUN echo "deb http://netboot.in.nuxeo.com/ubuntu-security/ trusty-security main restricted universe multiverse" >> /etc/apt/sources.list
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update || true
RUN apt-get -q -y dist-upgrade
RUN apt-get -q -y install locales unzip
RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales
RUN update-locale LANG=en_US.UTF-8
RUN apt-get install -q -y postgresql libpq-dev python-psycopg2 openjdk-7-jdk libreoffice imagemagick poppler-utils ffmpeg2theora ufraw libwpd-tools git redis-server redis-tools rsync xvfb x11vnc fluxbox

#RUN git clone https://github.com/nuxeo/ffmpeg-nuxeo.git
#ENV BUILD_YASM true
#RUN cd ffmpeg-nuxeo && ./build-all.sh true
#RUN rm -rf ffmpeg-nuxeo

RUN sed -i 's/daemonize yes/daemonize no/g' /etc/redis/redis.conf
RUN mkdir /etc/service/redis
ADD files/redis /etc/service/redis/run
RUN chmod +x /etc/service/redis/run

# Add sudoer user
RUN useradd -d /home/ubuntu -m -s /bin/bash ubuntu
RUN echo "\nubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Add jenkins user
RUN useradd -d /opt/jenkins -m -s /bin/bash jenkins

RUN mkdir /etc/service/xvfb
ADD files/xvfb /etc/service/xvfb/run
RUN chmod +x /etc/service/xvfb/run

RUN mkdir /etc/service/x11vnc
ADD files/x11vnc /etc/service/x11vnc/run
RUN chmod +x /etc/service/x11vnc/run

RUN mkdir /etc/service/fluxbox
ADD files/fluxbox /etc/service/fluxbox/run
RUN chmod +x /etc/service/fluxbox/run

RUN mkdir /home/ubuntu/.ssh
ADD files/id_rsa.pub /home/ubuntu/.ssh/authorized_keys
RUN chown -R ubuntu:ubuntu /home/ubuntu/.ssh
RUN chmod 0600 /home/ubuntu/.ssh/authorized_keys
RUN chmod 0700 /home/ubuntu/.ssh

RUN echo "UsePAM yes" >> /etc/ssh/sshd_config
RUN rm -f /etc/service/sshd/down

EXPOSE 22

ADD files/rc.local /etc/rc.local
RUN chmod +x /etc/rc.local

CMD ["/sbin/my_init"]

