#Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
#
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle WebLogic 12.2.1.3 domain persisted on a Docker volume
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Run:
#      $ docker build -f Dockerfile -t 12213-weblogic-domain-in-volume .
#
# IMPORTANT
# ---------
# The resulting image of this Dockerfile contains a WebLogic Domain.
#
# From
# ----
FROM s4intlaurent/weblogic:12.2.1.2
# Maintainer
# ----------
MAINTAINER Davi Junior <davi.vjunior@telefonica.com>

# WLS Configuration
# -----------------
ENV CUSTOM_DOMAIN_NAME="${CUSTOM_DOMAIN_NAME:-base_domain}" \
    CUSTOM_DOMAIN_ROOT="/u01/oracle/user_projects/domains" \
    CUSTOM_ADMIN_PORT="${CUSTOM_ADMIN_PORT:-7001}" \
    CUSTOM_ADMIN_NAME="${CUSTOM_ADMIN_NAME:-admin}" \
    CUSTOM_ADMIN_HOST="${CUSTOM_ADMIN_HOST:-AdminContainer}" \
    CUSTOM_MANAGED_SERVER_PORT="${CUSTOM_MANAGED_SERVER_PORT:-8001}" \
    CUSTOM_MANAGED_SERVER_NAME_BASE="${CUSTOM_MANAGED_SERVER_NAME_BASE:-WLS_SIGRES_DM_}" \
    CUSTOM_CONFIGURED_MANAGED_SERVER_COUNT="${CUSTOM_CONFIGURED_MANAGED_SERVER_COUNT:-2}" \
    CUSTOM_MANAGED_NAME="${CUSTOM_MANAGED_NAME:-MS1}" \
    CUSTOM_CLUSTER_NAME="${CUSTOM_CLUSTER_NAME:-WLS_SIGRES_DM_CLUSTER}" \
    CUSTOM_CLUSTER_TYPE="${CUSTOM_CLUSTER_TYPE:-CONFIGURED}" \
    CUSTOM_PRODUCTION_MODE_ENABLED="${CUSTOM_PRODUCTION_MODE_ENABLED:-prod}" \
    PROPERTIES_FILE_DIR="/u01/oracle/properties" \
    EXTRA_JAVA_PROPERTIES="-Dreconf.client.file.location=/u01/oracle/properties/reconf.properties"  \
    #CUSTOM_JAVA_OPTIONS="-Xdebug -Xnoagent -Xrunjdwp:transport=dt_socket,address=4000,server=y,suspend=n"  \
    CUSTOM_JAVA_OPTIONS="-agentlib:jdwp=transport=dt_socket,address=4000,suspend=n,server=y"  \
    CUSTOM_PATH="$PATH:${JAVA_HOME}/bin:/u01/oracle/oracle_common/common/bin:/u01/oracle/wlserver/common/bin:/u01/oracle/container-scripts"

# Add files required to build this image
COPY container-scripts/* /u01/oracle/container-scripts/
COPY properties/* /u01/oracle/properties/

#Create directory where domain will be written to
USER root
RUN mkdir -p $CUSTOM_DOMAIN_ROOT && \
    chown -R oracle:oracle $CUSTOM_DOMAIN_ROOT && \
    chmod -R a+xwr $CUSTOM_DOMAIN_ROOT && \
    mkdir -p $ORACLE_HOME/properties && \
    mkdir -p $ORACLE_HOME/artefatos && \
    chown -R oracle:oracle $ORACLE_HOME/artefatos && \
    chmod -R 777 $ORACLE_HOME/properties && \ 
    chmod -R 777 /etc/hosts && \
    chmod +x /u01/oracle/container-scripts/*

#CMD /u01/oracle/container-scripts/addHosts.sh

VOLUME $CUSTOM_DOMAIN_ROOT

USER oracle
WORKDIR $ORACLE_HOME
CMD /u01/oracle/container-scripts/createWLSDomain.sh; sleep infinity
