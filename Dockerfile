FROM centos:centos7

# The following provides a simple way to bypass any cached image builds.
# It can also be adjusted as a simple way to add all the latest centos 
# patches to the image.
# 
ENV PATCH_LEVEL 20181221

MAINTAINER David King <dsmk@bu.edu>

#ENV JRE_HOME /opt/jre1.8.0_60

RUN yum -y update \
  && yum -y install wget epel-release \
  && wget http://download.opensuse.org/repositories/security://shibboleth/CentOS_7/security:shibboleth.repo -P /etc/yum.repos.d \
  && yum -y install httpd shibboleth.x86_64 \
  && rm /etc/shibboleth/sp-*.pem \
  && yum clean all

COPY httpd-foreground /usr/bin/

RUN mkdir -p /var/run/lock /var/lock/subsys \
  && chmod +x /etc/shibboleth/shibd-redhat /usr/bin/httpd-foreground

# These default paths are designed to fit with the default Docker secret approach - see 
# docker-compose.yml for an example of mapping a volume for that location and 
# docker-compose-secrets.yml for an example where the secret is referenced in the docker-compose
# format.
#
ENV SHIB_SP_KEY /run/secrets/SHIB_SP_KEY
ENV SHIB_SP_CERT /run/secrets/SHIB_SP_CERT

EXPOSE 80

# now we have our test SP configuration
#COPY shibboleth /var/www/cgi-bin
COPY printenv /var/www/cgi-bin/
COPY shib_test.conf /etc/httpd/conf.d/shib_test.conf

ADD shibboleth-sp/ /etc/shibboleth/

RUN chmod +x /var/www/cgi-bin/*

# if we set the following variables then 
CMD ["httpd-foreground"]
