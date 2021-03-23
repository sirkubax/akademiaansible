#FROM ubuntu
#
#RUN apt-get update && apt-get install -y vim python3-virtualenv git netcat
##VOLUME ["/sys/fs/cgroup", "/tmp", "/run"]
#
#COPY docker-entrypoint.sh /entrypoint.sh
#ENTRYPOINT ["/entrypoint.sh", "&"]

FROM ubuntu

# Update the repository sources list
RUN apt-get update

ARG DEBIAN_FRONTEND=noninteractive
# Install and run apache
RUN apt-get install -y apache2 net-tools && apt-get clean

#ENTRYPOINT ["/usr/sbin/apache2", "-k", "start"]

#ENV APACHE_RUN_USER www-data
#ENV APACHE_RUN_GROUP www-data
#ENV APACHE_LOG_DIR /var/log/apache2

ENTRYPOINT ["apachectl", "-D", "FOREGROUND"]
