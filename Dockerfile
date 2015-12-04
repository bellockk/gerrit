FROM java:8-jdk

MAINTAINER Kenneth E. Bellock <ken.bellock@segmail.com>

ENV GERRIT_VERSION 2.11.4
ENV GERRIT_SHA 6de25f623ae2906c6e25dd766cda4654af0459af

ENV TINI_VERSION 0.5.0
ENV TINI_SHA 066ad710107dc7ee05d3aa6e4974f01dc98f3888

ENV GERRIT_CONF gerrit.conf
ENV GERRIT_HOME /var/gerrit
ENV GERRIT_USER gerrit2
ENV GERRIT_SOURCE gerrit-${GERRIT_VERSION}.war
ENV GERRIT_WAR ${GERRIT_HOME}/gerrit.war
ENV GERRIT_URL https://www.gerritcodereview.com/download/$GERRIT_SOURCE
ENV TINI_URL https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-static
ENV TINI /bin/tini

RUN set -x && apt-get update && apt-get install -y git curl gitweb && rm -rf /var/lib/apt/lists/* \
    && useradd -m -d "$GERRIT_HOME" -u 1000 -s /bin/bash -U $GERRIT_USER \
    && curl -fL $TINI_URL -o $TINI && chmod +x $TINI \
    && echo "$TINI_SHA $TINI" | sha1sum -c -

USER $GERRIT_USER
RUN set -x && curl -fL $GERRIT_URL -o $GERRIT_WAR \
    && echo "$GERRIT_SHA $GERRIT_WAR" | sha1sum -c - \
    && mkdir -p ${GERRIT_HOME}/lib \
    && java -jar $GERRIT_WAR init --batch --no-auto-start -d $GERRIT_HOME \
    && curl -fL https://gerrit-ci.gerritforge.com/job/plugin-avatars-external-master/lastSuccessfulBuild/artifact/buck-out/gen/plugins/avatars-external/avatars-external.jar -o ${GERRIT_HOME}/plugins/avatars-external.jar \
    && curl -fL https://gerrit-ci.gerritforge.com/job/plugin-delete-project-stable-2.11/lastSuccessfulBuild/artifact/buck-out/gen/plugins/delete-project/delete-project.jar -o ${GERRIT_HOME}/plugins/delete-project.jar \
    && curl -fL https://gerrit-ci.gerritforge.com/job/plugin-its-bugzilla-stable-2.11/lastSuccessfulBuild/artifact/buck-out/gen/plugins/its-bugzilla/its-bugzilla.jar -o ${GERRIT_HOME}/plugins/its-bugzilla.jar \
    && curl -fL https://gerrit-ci.gerritforge.com/job/plugin-wip-master/lastSuccessfulBuild/artifact/buck-out/gen/plugins/wip/wip.jar -o ${GERRIT_HOME}/plugins/wip.jar \
    && rm -fr ${GERRIT_HOME}/git

USER root
VOLUME $GERRIT_HOME
EXPOSE 8080 29418
CMD ["/bin/tini", "--", "/usr/bin/java", "-jar", \
     "/var/gerrit/gerrit.war", "daemon", "--console-log", "-d", \
     "/var/gerrit"]
