#!/bin/bash -e
#
# Script for initializing NEO4J Server Config
# This script must be run as the neo4j user
# and must be run as super user
# Script tested on 5/22/2016 by Christopher Upkes
#################################################

#------------------------------------------------ 
# Script variables
#------------------------------------------------
# create a standard logging tag for all log entries
LOGTAG=NEO4J_SUPPORT
# specify the neo4j directory tree
NEOHOME="/opt/neo4j/neo4j-enterprise-2.3.3"
NEOBASE="/opt/neo4j"
NEOSUPP="/opt/neo4j_support"
NEOBIN="$NEOSUPP/bin"
NEOETC="$NEOSUPP/etc"
NEOBAK="$NEOBASE/backup"
NEOCONF="$NEOHOME/conf"
NEOLOG=neo4j_install.log
#NEOBASE="/db/neo4j"
#NEOBIN="/db/neo4j_support/bin""
#NEOETC="/db/neo4j_support/etc"
#NEOBAK="/db/neo4j/backup"
# pointers to all support files included in the support tarball
CONF_FILE=neo4j_support.conf
CLUSTER_CONFIG=cluster.conf
# samba files
SAMBA_FILE=neoj4_smb.conf
SAMBA_SCRIPT=samba_config.sh
# firewall files
FIREWALL_SCRIPT=firewall_config.sh
# neo4j cluster configuration files
NEO4J_WRAP_FILE=neo4j-wrapper.conf
NEO4J_PROP_FILE=neo4j.properties
NEO4J_SRV_PROP_FILE=neo4j-server.properties
# support tarballs
SUPPORT_TGZ_FILE=neo4j_support.tar.gz
NEO4J_SERVER_TGZ=neo4j-enterprise-2.3.3-unix.tar.gz
# monitoring, backup and diagnostics scripts
SUPPORT_SCRIPT=neo4j_support_diags.sh
MONITOR_SCRIPT=neo4j_monitor.sh
BACKUP_SCRIPT=neo4j_backup_routine.sh
# provide address for monitoring and security emails
# this can be one or more adddresses, separated by commas
ADMIN_EMAIL=dongyang@microsoft.com
# provide the crontab entry for the intrusion detection module
AIDE_ENTRY="0 1 * * * /usr/sbin/aide --check"
INIT_HOST="NO"
INIT_HOST_FILE=neo4j_host_init.sh


#------------------------------------------------
# End script variables
#------------------------------------------------
CURRDIR=$(pwd)

if [ -e $NEOLOG ]; then
	echo "located log file"
	echo "---------------------------------------------" >> $NEOLOG
	echo "$(date) : begin Neo4J installation logging --" >> $NEOLOG
else
	echo "unable to locate log file, creating new log file"
	echo "$(date) : begin Neo4J installation logging --" > $NEOLOG
fi

if [ -e $CLUSTER_CONFIG ]; then
	echo "located cluster config file"
else
	echo "could not locate cluster configruation file, aborting script"
	exit 1
fi

source $CURRDIR/$CLUSTER_CONFIG

# the node details of the script destination
THISH=$NODE1_HN
THISIP=$NODE1_IP
THISNUM=1
$INIT_HOST=$INITIALIZE_HOST # update the INIT_HOST value from the cluster configuration

echo "this server number is $THISNUM"
#------------------------------------------------
# Create Neo4j directory structures
#------------------------------------------------

echo "Creating Neo4j home and support directories"

mkdir -p $NEOETC && chmod 755 $NEOETC
mkdir -p $NEOBIN && chmod 755 $NEOBIN
mkdir -p $NEOBAK && chmod 755 $NEOBAK

echo "$(date) neo4j directory structure created" >> $NEOLOG
#
logger -p local0.notice -t $LOGTAG "neo4j home and support directories created"

#------------------------------------------------
# Update current user (Neo4j) .bash_profile
#------------------------------------------------

# make sure the neo4j home directory exists

if [ -d /home/neo4j ]; then
	echo "located neo4j home directory"
else
	echo "could not locate neo4j home directory, aborting script"
	exit 2
fi

#
# update the profile script to include essential path values
# and helpful aliases and shell configurations
#

echo "updating .bash_profile"

cp /home/neo4j/.bash_profile /home/neo4j/.bash_profile.bak

cat << ENDOC >> /home/neo4j/.bash_profile
# NEO4J SUPPORT MODIFICATION
if [ -d "/opt/neo4j" ] ; then
	PATH=$PATH:opt/neo4j
fi
if [ -d "/opt/neo4j_support/bin" ] ; then
	PATH=$PATH:/opt/neo4j_support/bin
fi
if [ -d "/opt/neo4j_support/etc" ] ; then
	PATH=$PATH:/opt/neo4j_support/etc
fi
if [ -d "/opt/neo4j/backup" ] ; then
	export NEO4J_BACKUP=/opt/neo4j/backup
fi
if [ -d "/opt/neo4j/neo4j-enterprise-2.3.3" ] ; then
	export NEO4J_HOME=/opt/neo4j/neo4j-enterprise-2.3.3
fi
set -o noclobber
unset MAILCHECK
export LANG=C
export PATH
alias df='df -h'
alias rm='rm -i'
alias h='history | tail'
alias neo='cd /opt/neo4j'
# END NEO4J SUPPORT MODIFICATION
ENDOC

logger -p local0.notice -t $LOGTAG "user $USER profile updated"

echo "neo4j user .bash_profile updated" >> $NEOLOG

#------------------------------------------------
# Populate Neo4j directories with Neo4j files
#------------------------------------------------

# return to the neo4j home directory




#
# Now that the neo4j server and support directory structures
# are created we can deploy the support configuration files and scripts
#

# uncompress the neo4j support tarball

echo "uncomrpessing support tarball"


if [ -e $SUPPORT_TGZ_FILE ]; then
	tar -zxvf $SUPPORT_TGZ_FILE -C $NEOBASE && logger -p local0.notice -t $LOGTAG "support files loaded"
	echo "uncompressed support tar file"
else
	echo "unable to locate neo4j support tar file, aborting script, $SUPPORT_TGZ_FILE"
	echo "$(date) ERROR:  unable to locate support tar file $SUPPORT_TGZ_FILE, aborting script"  >> $NEOLOG
	exit 3
fi

cd $NEOBASE

# copying support files to proper directories

echo "$(date) copying support files " >> $NEOLOG

if [ -e $CONF_FILE ]; then cp $CONF_FILE $NEOETC/$CONF_FILE && echo "$CONF_FILE copied" ; fi
if [ -e $NEO4J_PROP_FILE ]; then cp $NEO4J_PROP_FILE $NEOETC/$NEO4J_PROP_FILE && echo "$NEO4J_PROP_FILE copied"; fi
if [ -e $NEO4J_SRV_PROP_FILE ]; then cp $NEO4J_SRV_PROP_FILE $NEOETC/$NEO4J_SRV_PROP_FILE && echo "$NEO4J_SRV_PROP_FILE copied"; fi
if [ -e $NEO4J_WRAP_FILE ]; then cp $NEO4J_WRAP_FILE $NEOETC/$NEO4J_WRAP_FILE && echo "$NEO4J_WRAP_FILE copied"; fi
if [ -e $MONITOR_SCRIPT ]; then cp $MONITOR_SCRIPT $NEOETC/$MONITOR_SCRIPT && echo "$MONITOR_SCRIPT copied"; fi

logger -p local0.notice -t $LOGTAG "support files deployed"

# uncompress neo4j enterprise server tarball

cd $CURRDIR
cp $NEO4J_SERVER_TGZ $NEOBASE/$NEO4J_SERVER_TGZ
tar -zxvf $NEOBASE/$NEO4J_SERVER_TGZ -C $NEOBASE && logger -p local0.notice -t $LOGTAG "Neo4j Enterprise Server files deployed"

# backup existing configuration files and copy over provided configuration files

if [ -d $NEOCONF ]; then
	cd $NEOCONF
	mv $NEO4J_PROP_FILE $NEO4J_PROP_FILE.bak && cp $NEOETC/$NEO4J_PROP_FILE $NEO4J_PROP_FILE
	mv $NEO4J_SRV_PROP_FILE $NEO4J_SRV_PROP_FILE.bak && cp $NEOETC/$NEO4J_SRV_PROP_FILE $NEO4J_SRV_PROP_FILE
	mv $NEO4J_WRAP_FILE $NEO4J_WRAP_FILE.bak && cp $NEOETC/$NEO4J_WRAP_FILE $NEO4J_WRAP_FILE
	
	logger -p local0.notice -t $LOGTAG "neo4j cluster configuration files deployed"
	
	# update server properties file with cluster configuration details
	
	sed -i s/xthis_server_num/$THISNUM/g $NEO4J_PROP_FILE && echo "updated $NEO4J_PROP_FILE"
	sed -i s/xsrv1ip/$NODE1_IP/g $NEO4J_PROP_FILE && echo "updated $NEO4J_PROP_FILE"
	sed -i s/xsrv2ip/$NODE2_IP/g $NEO4J_PROP_FILE && echo "updated $NEO4J_PROP_FILE"
	sed -i s/xsrv3ip/$NODE3_IP/g $NEO4J_PROP_FILE && echo "updated $NEO4J_PROP_FILE"
	sed -i s/xthis_server_ip/$THISIP/g $NEO4J_PROP_FILE && echo "updated $NEO4J_PROP_FILE"
	
	
	logger -p local0.notice -t $LOGTAG "neo4j cluster configuration updated"
else
	echo "cannot locate neo4j home directory"
	echo "manual configuration of neo4j cluster is required"
	echo "$(date) ERROR: unable to locate home directory" >> $NEOLOG
	echo "$(date) ERROR: manual configuration of neo4j cluster required" >> $NEOLOG
	
	logger -p local0.notice -t $LOGTAG "unable to deploy neo4j ccluster configuration files"
fi

cd $CURRDIR

#------------------------------------------------
# Set Neo4j Server specific os configurations
#------------------------------------------------

#
# we need to update some server configuration files
# in order for the neo4j cluster to function properly
#
if [ -e /etc/security/limits.conf ]; then
cp /etc/security/limits.conf /etc/security/limits.conf.bak
cat << ENDOC >> /etc/security/limits.conf
# NEO4J SUPPORT MODIFICATION
neo4j   soft    nofile  40000
neo4j   hard    nofile  40000
# END NEO4J SUPPORT MODIFICATION
ENDOC
	
logger -p local0.notice -t $LOGTAG "limits.conf modified"
echo "modified limits.conf"
else
	echo "unable to locate limits.conf file"
	echo "$(date) ERROR: unable to locate limits.conf file.  Manual config required" >> $NEOLOG
fi

if [ -e /etc/pam.d/su ]; then
cp /etc/pam.d/su /etc/pam.d/su.bak
cat << ENDOC >> /etc/pam.d/su
# NEO4J SUPPORT MODIFICATION
session    required   pam_limits.so
# END NEO4J SUPPORT MODIFICATION
ENDOC
logger -p local0.notice -t $LOGTAG "/etc/pam.d/su file modified"
echo "modified /etc/pam.d/su file"

else
	echo "unable to locate /etc/pam.d/su file"
	echo "$(date) ERROR: unable to locate /etc/pam.d/su file.  Manual config required" >> $NEOLOG
fi



# A restart is required for the settings to take effect.
# After the above procedure, the neo4j user will have a limit of 40 000 simultaneous open files.
# If you continue experiencing exceptions on Too many open files or Could not stat() directory,
# you may have to raise the limit further.

echo "required server configuration changes complete."
echo "System must be restarted before changes take affect"

#------------------------------------------------
# Update network information
#------------------------------------------------

#
# Although most of our configuration details use ip addresses,
# we add nodes to host file so we can reference
# all nodes in the cluster by their actual hostnames
#
if [ -e /etc/hosts ]; then
cp /etc/hosts /etc/hosts.bak
cat << ENDOC >> /etc/hosts
# NEO4J SUPPORT MODIFICATION
$NODE1_IP	$NODE1_HN
$NODE2_IP	$NODE2_HN
$NODE3_IP	$NODE3_HN
# END NEO4J SUPPORT MODIFICATION
ENDOC
echo "modified /etc/hosts file"
logger -p local0.notice -t $LOGTAG "/etc/hosts modified"
else
	echo "unable to locate /etc/hosts file"
	echo "$(date) ERROR: unable to locate /etc/hosts file. Manual config required"
fi

#------------------------------------------------
# Configure backup scheduler
#------------------------------------------------

#
# we have a neo4j-specific backup script that defines
# a weekly backup with incremental backups between weekly fulls.
# Since the cluser will be batch-loaded, this backup script
# will be copied to the neo4j_support/bin directory
# but will not be copied to /etc/cron.daily
#


if [ -e $NEOBASE/$BACKUP_SCRIPT ]; then
	cp $NEOBASE/$BACKUP_SCRIPT $NEOBIN/$BACKUP_SCRIPT
	echo "backup script copied to $NEOBIN"
	echo "to schedule backup routine copy  $BACKUP_SCRIPT to /etc/cron.daily"
else
	echo "could not locate backup routine script"
	echo "$(date) ERROR:  could not locate backup routine script"
fi

#------------------------------------------------
# Deploy monitoring script
#------------------------------------------------

#
# A neo4j monitoring script already has a routine for monitoring
# the space available in the neo4j/backup directory
# Other monitoring routines should be added to the script.
# 

if [ -e $NEOBASE/$MONITOR_SCRIPT ]; then
	cp $NEOBASE/$MONITOR_SCRIPT /etc/cron.daily/$MONITOR_SCRIPT && chmod +x /etc/cron.daily/$MONITOR_SCRIPT
	echo "copied monitor script to /etc/cron.daily/"
	logger -p local0.notice -t $LOGTAG "file : $MONITOR_SCRIPT added to cron.daily"
else
	echo "could not locate monitor script $MONITOR_SCRIPT"
	echo "$(date) ERROR:  could not locate monitor script, $MONITOR_SCRIPT"
fi



#------------------------------------------------
# Deploy and execute diagnostics script
#------------------------------------------------

#
# The support diagnostics script will be copied to the neo4j_support/bin directory.
# This script is used to provide the support team with a full set
# of diagnostic information for use with troubleshooting production issues.
#

if [ -e $NEOBASE/$SUPPORT_SCRIPT ]; then
	cp $NEOBASE/$SUPPORT_SCRIPT $NEOBIN/$SUPPORT_SCRIPT && chmod +x $NEOBIN/$SUPPORT_SCRIPT
	echo "copied support script"
else	
	echo "could not locate support script, $SUPPORT_SCRIPT"
	echo "$(date) ERROR: could not locate support script, $SUPPORT_SCRIPT"
fi

#------------------------------------------------
# Ensure proper ownership of directories and files
#------------------------------------------------

#
# After creating and deploying all files and directories
# we want to make sure that we have the appropriate
# user and group ownership defined
#
cd $CURRDIR

chown -R neo4j:neo4j $NEOBASE
chown -R neo4j:neo4j $NEOSUPP

logger -p local0.notice -t $LOGTAG "neo4j file and directory ownership changed"

#------------------------------------------------
# Initialize host machine
# includes installing Java, Intrustion Detection,
# Auditing, Samba and Firewall Configuration
#------------------------------------------------

if [[ $INIT_HOST = "YES" && -e $INIT_HOST_FILE ]]; then
	chmod +x $INIT_HOST_FILE
	source $INIT_HOST_FILE
	if [ $? -ne 0 ]; then
		echo "script $INIT_HOST_FILE returned error code, aborting script"
		echo "ERROR: $INIT_HOST_FILE script returned error code." >> $NEOLOG
	fi
else
	if [ $INIT_HOST = "YES" ]; then
	echo "failed to locate $INIT_HOST_FILE script file, aborting script"
	echo "ERROR: failed to locate $INIT_HOST_FILE script file." >> $NEOLOG
	fi
fi
	
echo "$(date) Neo4j_init.sh script fiinished"








