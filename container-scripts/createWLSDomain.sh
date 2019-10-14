#!/bin/bash
#
#Copyright (c) 2014, 2019 Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.

# If AdminServer.log does not exists, container is starting for 1st time
# So it should start NM and also associate with AdminServer
# Otherwise, only start NM (container restarted)
########### SIGTERM handler ############
function _term() {
   echo "Stopping container."
   echo "SIGTERM received, shutting down the server!"
   ${DOMAIN_HOME}/bin/stopWebLogic.sh
}

########### SIGKILL handler ############
function _kill() {
   echo "SIGKILL received, shutting down the server!"
   kill -9 $childPID
}

# Set SIGTERM handler
trap _term SIGTERM

# Set SIGKILL handler
trap _kill SIGKILL

export DOMAIN_HOME=$CUSTOM_DOMAIN_ROOT/$CUSTOM_DOMAIN_NAME
export WL_HOME=$CUSTOM_DOMAIN_ROOT
echo "Domain Home is:  $DOMAIN_HOME"

if [  -f ${DOMAIN_HOME}/servers/${CUSTOM_ADMIN_NAME}/logs/${CUSTOM_ADMIN_NAME}.log ]; then
    exit
fi

SEC_PROPERTIES_FILE=${PROPERTIES_FILE_DIR}/domain_security.properties
echo $SEC_PROPERTIES_FILE
if [ ! -e "${SEC_PROPERTIES_FILE}" ]; then
   echo "A properties file with the username and password needs to be supplied."
   exit
fi

# Get Username
USER=`awk '{print $1}' ${SEC_PROPERTIES_FILE} | grep username | cut -d "=" -f2`
if [ -z "${USER}" ]; then
   echo "The domain username is blank.  The Admin username must be set in the properties file."
   exit
fi

# Get Password
PASS=`awk '{print $1}' ${SEC_PROPERTIES_FILE} | grep password | cut -d "=" -f2`
if [ -z "${PASS}" ]; then
   echo "The domain password is blank.  The Admin password must be set in the properties file."
   exit
fi

DOMAIN_PROPERTIES_FILE=${PROPERTIES_FILE_DIR}/domain.properties
echo $DOMAIN_PROPERTIES_FILE
if [ ! -e "${DOMAIN_PROPERTIES_FILE}" ]; then
   echo "A Domain properties file needs to be supplied."
   exit
fi

# Create domain
wlst.sh -skipWLSModuleScanning -loadProperties ${DOMAIN_PROPERTIES_FILE} -loadProperties ${SEC_PROPERTIES_FILE} -loadProperties properties/version.properties  /u01/oracle/container-scripts/create-wls-domain.py
#wlst.sh -skipWLSModuleScanning -loadProperties ${DOMAIN_PROPERTIES_FILE} -loadProperties ${SEC_PROPERTIES_FILE} -loadProperties /u01/oracle/container-scripts/create-wls-domain.py
retval=$?

echo  "RetVal from Domain creation $retval"

if [ $retval -ne 0 ];
then
   echo "Domain Creation Failed.. Please check the Domain Logs"
   exit
fi

# Create the security file to start the server(s) without the password prompt
mkdir -p ${DOMAIN_HOME}/servers/${CUSTOM_ADMIN_NAME}/security/
echo "username=${USER}" >> ${DOMAIN_HOME}/servers/${CUSTOM_ADMIN_NAME}/security/boot.properties
echo "password=${PASS}" >> ${DOMAIN_HOME}/servers/${CUSTOM_ADMIN_NAME}/security/boot.properties

#Set Java options

${DOMAIN_HOME}/bin/setDomainEnv.sh


# BAIXA ARTEFATO
#export PACKAGE=$(curl -s -X GET "http://10.129.178.173:8082/service/rest/v1/search/assets?direction=asc&name=sigitm-jsf" -H "accept: application/json" |grep '.war'|grep downloadUrl | cut -d':' -f2- | cut -d'"' -f2 | head -1)
#curl $PACKAGE --output /u01/oracle/artefatos/sigitm-jsf.war
#export PACKAGE_NAME=$(ls /u01/oracle/artefatos/)

#echo "Starting the Admin Server"
#echo "=========================="

# Start Admin Server and tail the logs
mkdir -p /u01/oracle/wlserver/common/nodemanager/
cp /u01/oracle/properties/nodemanager.* /u01/oracle/wlserver/common/nodemanager/
export NODEMGR_HOME=/u01/oracle/wlserver/common/nodemanager/
$ORACLE_HOME/wlserver/server/bin/startNodeManager.sh &
JAVA_OPTIONS=${CUSTOM_JAVA_OPTIONS} ${DOMAIN_HOME}/startWebLogic.sh &

sleep 15
# Cria datasource
#wlst.sh -skipWLSModuleScanning -loadProperties /u01/oracle/properties/datasource.properties.oracle /u01/oracle/container-scripts/ds-deploy.py

export PACKAGE_VERSION=`awk -F/ '{print ((NF>1)?$(NF-1)"/":"")""$NF}' <<< $(curl -s "http://10.129.178.173:8082/service/rest/v1/search/assets?sort=version&direction=desc&repository=oss-snapshot&name=sigitm-jsf&maven.extension=war" -H "accept: application/json" |grep '.war'|grep downloadUrl | cut -d':' -f2- | cut -d'"' -f2 | head -1 ) | cut -d/ -f1`
echo "PACKAGE_VERSION=$PACKAGE_VERSION" > properties/version.properties

wlst.sh -skipWLSModuleScanning -loadProperties ${DOMAIN_PROPERTIES_FILE} -loadProperties ${SEC_PROPERTIES_FILE}  /u01/oracle/container-scripts/start-servers.py 

rm -rf properties/version.properties

childPID=$!
wait $childPID

