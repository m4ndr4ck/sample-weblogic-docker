#Copyright (c) 2014, 2019, Oracle and/or its affiliates. All rights reserved.
#
#Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
#
# WebLogic on Docker Default Domain
#
# Domain, as defined in DOMAIN_NAME, will be created in this script. Name defaults to 'base_domain'.
#
# Since : June, 2019
# Author: monica.riccelli@oracle.com
# ===================================

import os
import socket

def getNmHomeDirectory():
    wlsHome = str(java.lang.System.getProperty('pineapple.weblogic.home.path'))
    #return wlsHome + '/common/nodemanager'
    return '/u01/oracle/wlserver/common/nodemanager'

#def startNm():
#    home=getNmHomeDirectory()
#    startNodeManager(verbose='true', NodeManagerHome=home, ListenPort='5556', SecureListener='false', ListenAddress='localhost', nmType='plain')

def createMachine(machineName, machineListenAddress):
    cd('/')
    machine = create(machineName, 'Machine')
    cd('/Machine/' + machineName)
    nodeMgr = create(machineName, 'NodeManager')
    nodeMgr.setListenAddress('localhost')
    nodeMgr.setListenPort(5556)
    nodeMgr.setNMType('plain')
    nodeMgr.setDebugEnabled(True)
    nodeMgr.setNodeManagerHome(getNmHomeDirectory())
    return machine

def setMachine(machineName, serverName):
    cd('/')
    cd('/Servers/')
    cd(serverName)
    currentServer = cmo;
    cd('/Machine/' + machineName)
    currentServer.setMachine(cmo)

def getEnvVar(var):
  val=os.environ.get(var)
  if val==None:
    print "ERROR: Env var ",var, " not set."
    sys.exit(1)
  return val

# This python script is used to create a WebLogic domain
domain_name                   = DOMAIN_NAME
server_1                      = SERVER_1
server_2                      = SERVER_2
machine                       = MACHINE
admin_server_name             = ADMIN_NAME
admin_port                    = int(ADMIN_PORT)
server_port                   = int(MANAGED_SERVER_PORT)
managed_server_name_base      = MANAGED_SERVER_NAME_BASE
number_of_ms                  = int(CONFIGURED_MANAGED_SERVER_COUNT)
domain_path                   = os.environ.get("DOMAIN_HOME")
wls_home                      = os.environ.get("WLS_HOME")
package_version               = os.environ.get("PACKAGE_VERSION")
cluster_name                  = CLUSTER_NAME
cluster_type                  = CLUSTER_TYPE
production_mode_enabled       = PRODUCTION_MODE_ENABLED

print('domain_path              : [%s]' % domain_path);
print('domain_name              : [%s]' % domain_name);
print('admin_server_name        : [%s]' % admin_server_name);
print('admin_port               : [%s]' % admin_port);
print('cluster_name             : [%s]' % cluster_name);
print('server_port              : [%s]' % server_port);
print('number_of_ms             : [%s]' % number_of_ms);
print('cluster_type             : [%s]' % cluster_type);
print('managed_server_name_base : [%s]' % managed_server_name_base);
print('production_mode_enabled  : [%s]' % production_mode_enabled);
print('package_version          : [%s]' % package_version);

# Open default domain template
# ============================
readTemplate("/u01/oracle/wlserver/common/templates/wls/wls.jar")

set('Name', domain_name)
setOption('DomainName', domain_name)
create(domain_name,'Log')
cd('/Log/%s' % domain_name);
set('FileName', '%s.log' % (domain_name))

# Configure the Administration Server
# ===================================
cd('/Servers/AdminServer')
set('ListenPort', admin_port)
set('Name', admin_server_name)


# Set the admin user's username and password
# ==========================================
cd('/Security/%s/User/weblogic' % domain_name)
cmo.setName(username)
cmo.setPassword(password)

# Write the domain and close the domain template
# ==============================================
setOption('OverwriteDomain', 'true')


# Create a cluster
# ================
cd('/')
cl=create(cluster_name, 'Cluster')

if cluster_type == "CONFIGURED":

  # Create managed servers
  for index in range(0, number_of_ms):
    cd('/')
    msIndex = index+1
    portNumber = int('70'+str(msIndex)+'0')

    cd('/')
    name = '%s%s' % (managed_server_name_base, msIndex)

    create(name, 'Server')
    cd('/Servers/%s/' % name )
    print('managed server name is %s' % name);
    set('ListenPort', portNumber)
    #set('ListenPort', 7010)
    set('NumOfRetriesBeforeMSIMode', 0)
    set('RetryIntervalBeforeMSIMode', 1)
    set('Cluster', cluster_name)

else:
  print('Configuring Dynamic Cluster %s' % cluster_name)

  templateName = cluster_name + "-template"
  print('Creating Server Template: %s' % templateName)
  st1=create(templateName, 'ServerTemplate')
  print('Done creating Server Template: %s' % templateName)
  cd('/ServerTemplates/%s' % templateName)
  cmo.setListenPort(server_port)
  cmo.setCluster(cl)

  cd('/Clusters/%s' % cluster_name)
  create(cluster_name, 'DynamicServers')
  cd('DynamicServers/%s' % cluster_name)
  set('ServerTemplate', st1)
  set('ServerNamePrefix', managed_server_name_base)
  set('DynamicClusterSize', number_of_ms)
  set('MaxDynamicClusterSize', number_of_ms)
  set('CalculatedListenPorts', false)

  print('Done setting attributes for Dynamic Cluster: %s' % cluster_name);

# Write Domain
# ============
createMachine(machine, admin_server_name)
setMachine(machine, server_1)
setMachine(machine, server_2)

writeDomain(domain_path)
closeTemplate()
print 'Domain Created'

# Update Domain
readDomain(domain_path)
cd('/')
if production_mode_enabled == "true":
  cmo.setProductionModeEnabled(true)
else: 
  cmo.setProductionModeEnabled(false)
updateDomain()
#startNm()
#nmStart("WLS_SIGRES_DM_1")
#nmStart("WLS_SIGRES_DM_2")
closeDomain()
print 'Domain Updated'
print 'Done'

# Exit WLST
# =========
exit()
