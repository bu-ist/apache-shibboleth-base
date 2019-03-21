FROM amazonlinux:1

ENV build  1

RUN yum -y install epel-release && yum clean all 
RUN yum -y install --enablerepo=epel bats dos2unix && yum clean all 

COPY *.sh ./
COPY tests/ ./tests/

RUN dos2unix ./test_bats.sh ./tests/*

ENV CONNECT testsp.bu.edu
ENV LANDSCAPE qa
ENV TESTBASE 1
CMD ["./test_bats.sh" ]

#CMD ["./test_app.sh", "-j", "test", "bufe-autotest-test"]

