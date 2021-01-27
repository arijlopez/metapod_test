FROM openjdk:8-jdk-stretch

# Install git lfs on Debian stretch per https://github.com/git-lfs/git-lfs/wiki/Installation#debian-and-ubuntu
# Avoid JENKINS-59569 - git LFS 2.7.1 fails clone with reference repository

# RUN apt-get update && apt-get upgrade -y && apt-get install -y git curl zip vim cron && curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash && apt-get install -y git-lfs && git lfs install && rm -rf /var/lib/apt/lists/*

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG http_port=8080
ARG agent_port=50000
ARG JENKINS_HOME=/var/jenkins_home
ARG REF=/usr/share/jenkins/ref
ARG jenkins_backup=/jenkins_backup
# jenkins version being bundled in this docker image
ARG JENKINS_VERSION

ENV JENKINS_HOME $JENKINS_HOME
ENV JENKINS_SLAVE_AGENT_PORT ${agent_port}
ENV REF $REF

ENV JENKINS_UC https://updates.jenkins.io
ENV JENKINS_UC_EXPERIMENTAL=https://updates.jenkins.io/experimental
ENV JENKINS_INCREMENTALS_REPO_MIRROR=https://repo.jenkins-ci.org/incrementals

ENV JENKINS_VERSION ${JENKINS_VERSION}
# Can be used to customize where jenkins.war get downloaded from
#ARG JENKINS_URL=https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/$JENKINS_VERSION/jenkins-war-$JENKINS_VERSION.war
ARG JENKINS_URL=http://mirrors.jenkins.io/war-stable/$JENKINS_VERSION/jenkins.war

# Use tini as subreaper in Docker container to adopt zombie processes
ARG TINI_VERSION=v0.16.1

ENV COPY_REFERENCE_FILE_LOG $JENKINS_HOME/copy_reference_file.log

# Install git lfs on Debian stretch per https://github.com/git-lfs/git-lfs/wiki/Installation#debian-and-ubuntu
# Avoid JENKINS-59569 - git LFS 2.7.1 fails clone with reference repository

RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y \
  git \
  curl \
  zip \
  vim \
  cron \
  && curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash \
  && apt-get install -y \
  git-lfs && \
  git lfs install && \
  rm -rf /var/lib/apt/lists/* \
# Jenkins is run with user `jenkins`, uid = 1000
# If you bind mount a volume from the host or a data container,
# ensure you use the same uid
  && mkdir -p $JENKINS_HOME \
  && mkdir -p $JENKINS_HOME/data/reports \
  && chown -R ${uid}:${gid} $JENKINS_HOME \
  && groupadd -g ${gid} ${group} \
  && useradd -d "$JENKINS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user} \
  && mkdir -p ${jenkins_backup} \
# $REF (defaults to `/usr/share/jenkins/ref/`) contains all reference configuration we want
# to set on a fresh new installation. Use it to bundle additional plugins
# or config file with your custom jenkins Docker image.
  && mkdir -p ${REF}/init.groovy.d \
  && mkdir -p /etc/chef/accepted_licenses

# Jenkins home directory is a volume, so configuration and build history
# can be persisted and survive image upgrades
# VOLUME $JENKINS_HOME

# $REF (defaults to `/usr/share/jenkins/ref/`) contains all reference configuration we want
# to set on a fresh new installation. Use it to bundle additional plugins
# or config file with your custom jenkins Docker image.
# RUN mkdir -p ${REF}/init.groovy.d

# ADD  files/jenkins_backup /jenkins_backup
COPY files ${jenkins_backup}

RUN mv ${jenkins_backup}/tini_pub.gpg ${JENKINS_HOME}/tini_pub.gpg \
  && mv ${jenkins_backup}/jenkins-support /usr/local/bin/jenkins-support \
  && mv ${jenkins_backup}/jenkins.sh /usr/local/bin/jenkins.sh \
  && mv ${jenkins_backup}/tini-shim.sh /bin/tini \
  && mv ${jenkins_backup}/a_maintanance_script /etc/cron.daily/a_maintanance_script \
  && mv ${jenkins_backup}/inspec /etc/chef/accepted_licenses \
  && mv ${jenkins_backup}/executors.groovy /usr/share/jenkins/ref/init.groovy.d/executors.groovy \
  && mv ${jenkins_backup}/secrets/ /etc/jenkins/ \
  && curl -fsSL https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-$(dpkg --print-architecture) -o /sbin/tini \
  && curl -fsSL https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-static-$(dpkg --print-architecture).asc -o /sbin/tini.asc \
  && gpg --no-tty --import ${JENKINS_HOME}/tini_pub.gpg \
  && gpg --verify /sbin/tini.asc \
  && rm -rf /sbin/tini.asc /root/.gnupg \
  && chmod +x /sbin/tini \
  && curl -fsSL ${JENKINS_URL} -o /usr/share/jenkins/jenkins.war \
  && zip -q -s 0 /jenkins_backup/jenkins_backup/jenkins_backup_latest_split.zip --out /jenkins_backup/jenkins_backup_latest.zip \
  && unzip -q -o /jenkins_backup/jenkins_backup_latest.zip  -d ${JENKINS_HOME} \
  && mv ${jenkins_backup}/run_inspec/config.xml ${JENKINS_HOME}/jobs/run_inspec/config.xml \
  && mv ${jenkins_backup}/queue.xml ${JENKINS_HOME}/queue.xml \
  && rm -rf ${jenkins_backup} \
  && curl https://packages.chef.io/files/stable/inspec/4.20.10/debian/9/inspec_4.20.10-1_amd64.deb > inspec_4.20.10-1_amd64.deb \
  && dpkg -i inspec_4.20.10-1_amd64.deb \
  && rm -rf inspec_4.20.10-1_amd64.deb \
  && mkdir -p /etc/jenkins \
  && ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
  && chmod -R 400 /etc/jenkins/ \
  && chown jenkins:jenkins /etc/jenkins/* \
  && chown jenkins:jenkins /bin/tini /usr/local/bin/jenkins.sh /usr/local/bin/jenkins-support /sbin/tini \
  && chmod +x /usr/local/bin/jenkins.sh \
  && chmod 0755 /etc/cron.daily/a_maintanance_script \
  && chown -R ${user} "$JENKINS_HOME" "$REF" \
  && apt-get purge -y \
  curl \
  zip \
  vim \
  && apt-get autoclean

#for main web interface:
EXPOSE ${http_port}

# will be used by attached slave agents:
EXPOSE ${agent_port}

USER ${user}

#ENTRYPOINT ["tail", "-f", "/dev/null"]

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/jenkins.sh"]
