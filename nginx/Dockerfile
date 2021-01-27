# FROM nginx:1.19.0-alpine
# FROM nginxinc/nginx-unprivileged:1.18-alpine-perl
FROM mitre/heimdall-lite:latest
ARG uid=1000
ARG gid=1000
ARG group=jenkins
ARG JENKINS_HOME=/usr/share/nginx/reports

#COPY ./files/default.conf /etc/nginx/conf.d/default.conf
#COPY ./files/index.html /usr/share/nginx/html/index.html

COPY ./files/default.conf.heimdall /etc/nginx/conf.d/default.conf

# jenkis user has to be added as it shares directory with jenkins container
RUN mkdir -p $JENKINS_HOME
RUN chown ${uid}:${gid} $JENKINS_HOME
RUN addgroup -g ${gid} ${group}
RUN adduser -h "${JENKINS_HOME}" -u ${uid} -G ${group} -s /bin/bash -D jenkins

#USER 101
# have to use root to use heimdall image
USER root
