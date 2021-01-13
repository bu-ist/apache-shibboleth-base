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
  && yum -y install httpd shibboleth.x86_64 dos2unix \
  && rm /etc/shibboleth/sp-*.pem \
  && yum clean all

RUN mkdir /entrypoints
COPY httpd-foreground /entrypoints/
COPY entrypoints.d/ /entrypoints/entrypoints.d/

RUN mkdir -p /var/run/lock /var/lock/subsys /var/www/html/server \
  && chmod +x /etc/shibboleth/shibd-redhat /entrypoints/httpd-foreground

# These private SP credentials are baked into the image because
# they are only used for automated internal testing and limited attribute
# release.  One should never do this for anything else.
#
# You can use these by adding the following environment variables to your container
# ENV SHIB_SP_KEY /etc/shibboleth/internal-test-only/sp-key.pem
# ENV SHIB_SP_CERT /etc/shibboleth/internal-test-only/sp-cert.pem
#
COPY internal-test-only/    /etc/shibboleth/internal-test-only/
COPY printenv  /var/www/cgi-bin/


# These default paths are designed to fit with the default Docker secret approach - see 
# docker-compose.yml for an example of mapping a volume for that location and 
# docker-compose-secrets.yml for an example where the secret is referenced in the docker-compose
# format.
#
ENV SHIB_SP_KEY /run/secrets/SHIB_SP_KEY
ENV SHIB_SP_CERT /run/secrets/SHIB_SP_CERT
ENV SP_HANDLER_URL /Shibboleth.sso
ENV SP_HOME_URL /


# Apache Config:

EXPOSE 80

COPY httpd.conf /etc/httpd/conf/httpd.conf
COPY conf.d/ /etc/httpd/conf.d/


COPY healthcheck /var/www/html/server/healthcheck

ADD shibboleth-sp/ /etc/shibboleth/

RUN chmod +x /var/www/cgi-bin/* && dos2unix /entrypoints/httpd-foreground /var/www/cgi-bin/printenv

ENTRYPOINT ["/entrypoints/httpd-foreground"]
