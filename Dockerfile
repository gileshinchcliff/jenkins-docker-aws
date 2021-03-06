FROM fedora:20

RUN yum update -y -q; yum clean all
RUN yum --enablerepo updates-testing install -y -q python-pip java-headless dejavu-sans-fonts git wget parallel which; yum clean all; pip install awscli

# Install jenkins
ENV JENKINS_VERSION 1.620
RUN yum install -y -q http://pkg.jenkins-ci.org/redhat/jenkins-${JENKINS_VERSION}-1.1.noarch.rpm

# Install docker (NB: Must mount in docker socket for it to work)
RUN curl -O -sSL https://get.docker.com/rpm/1.7.1/centos-7/RPMS/x86_64/docker-engine-1.7.1-1.el7.centos.x86_64.rpm
RUN yum localinstall -y --nogpgcheck docker-engine-1.7.1-1.el7.centos.x86_64.rpm

# Install kubectl
ENV KUBE_VER=1.0.1
ENV KUBE_URL=https://storage.googleapis.com/kubernetes-release/release/v${KUBE_VER}/bin/linux/amd64/kubectl
RUN /bin/bash -l -c "wget --quiet ${KUBE_URL} \
                     -O /usr/local/bin/kubectl && \
                     chmod +x /usr/local/bin/kubectl"

# Install S3 Secrets
RUN /usr/bin/mkdir -p /opt/bin
RUN URL=https://github.com/UKHomeOffice/s3secrets/releases/download/v0.0.1/s3secrets-0.0.1-linux-amd64 OUTPUT_FILE=/opt/bin/s3secrets MD5SUM=aecf1a0d9c0a113432bb15bb10d16541 /usr/bin/bash -c 'until [[ -x ${OUTPUT_FILE} ]] && [[ $(md5sum ${OUTPUT_FILE} | cut -f1 -d" ") == ${MD5SUM} ]]; do wget -q -O ${OUTPUT_FILE} ${URL} && chmod +x ${OUTPUT_FILE}; done'

ENV JENKINS_HOME /var/lib/jenkins

ADD jenkins.sh /srv/jenkins/jenkins.sh
ADD jenkins_backup.sh /srv/jenkins/jenkins_backup.sh

# User config / updates
# JENKINS_UC is needed to download plugins
ENV JENKINS_UC https://updates.jenkins-ci.org
COPY plugins.sh /usr/local/bin/plugins.sh
COPY plugins.base.txt /usr/share/jenkins/ref/
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/ref/plugins.base.txt
COPY plugins.txt /usr/share/jenkins/ref/
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/ref/plugins.txt

EXPOSE 8080
VOLUME /var/lib/jenkins
WORKDIR /var/lib/jenkins

ENTRYPOINT ["/srv/jenkins/jenkins.sh"]
