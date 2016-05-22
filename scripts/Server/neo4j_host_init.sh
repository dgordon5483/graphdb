#!/bin/bash -e
#
# Script for host confirguration
#################################################
LOGTAG=NEO4J_SUPPORT
# specify the neo4j directory tree
JDKCONF=jdk_config.sh
AIDECONF=aide_config.sh
AUDITCONF=audit_config.sh
SAMBACONF=samba_config.sh
SAMBAFILE=neo4j_samba.conf
FIREWCONF=firewall_config.sh
NEOLOG=neo4j_install.log
NEOSTAGE=/opt/neo4j
SAMBA="YES"
JDK="YES"
AIDE="YES"
FIREW="YES"
AUDIT="YES"


if [ -d $NEOSTAGE ]; then
	echo "$NEOSTAGE directory located"
	if [ -e $SAMBAFILE ]; then
		echo "$SAMBAFILE located"
	else
		echo "unable to locate $SAMBAFILE, skipping samaba install"
		$SAMBA="NO"
	fi
else
	echo "unable to locate $NEOBASE directory, skipping samba install"
	$SAMBA="NO"
fi

if [ -e $NEOLOG]; then
	echo "located log file"
else
	echo "unable to locate log file, creating new log file"
	echo "$(date) : begin Neo4J installation logging -- " $NEOLOG
fi

echo "$(date) : executing neo4j_init_host script" >> $NEOLOG

#------------------------------------------------
# Install a jdk
#------------------------------------------------

# 
# The neo4j cluser requires at minimum a java 6 jdk to be installed
#

if [ $JDK == "YES" ] && [ -e $JDKCONF ]; then
	chmod +x $JDKCONF
	./$JKDCONF
	if [ $? -ne 0 ]; then
		echo "script $JDKCONF returned error code, aborting script"
		echo "ERROR: $JDKCONF script returned error code." >> $NEOLOG
	fi
else
	echo "failed to locate $JDKCONF script file, aborting script"
	echo "ERROR: failed to locate $JDKCONF script file." >> $NEOLOG
fi


#------------------------------------------------
# Install intrusion detection package
#------------------------------------------------

if [ $AIDE == "YES" ] && [ -e $AIDECONF ]; then
	chmod +x $AIDECONF
	./$AIDECONF
	if [ $? -ne 0 ]; then
		echo "script $AIDECONF returned error code, aborting script"
		echo "ERROR: $AIDECONF script returned error code." >> $NEOLOG
	fi
else
	echo "failed to locate $AIDECONF script file, aborting script"
	echo "ERROR: failed to locate $AIDECONF script file." >> $NEOLOG
fi

#------------------------------------------------
# Install and configure auditing
#------------------------------------------------

#
# To ensure we meet the standard security certification guidelines,
# we need to make sure auditing is installed and running rules
# based on the considered requirements (stig, capp, nipsom, etc...).
# 
if [ $AUDIT == "YES" ] && [ -e $AUDITCONF ]; then
	chmod +x $AUDITCONF
	./$AUDITCONF
	if [ $? -ne 0 ]; then
		echo "script $AUDITCONF returned error code, aborting script"
		echo "ERROR: $AUDITCONF script returned error code." >> $NEOLOG
	fi
else
	echo "failed to locate $AUDITCONF script file, aborting script"
	echo "ERROR: failed to locate $AUDITCONF script file." >> $NEOLOG
fi


#------------------------------------------------
# Configure IPTABLES
#------------------------------------------------

#
# Although the Azure virtual switches control most of our network security
# we want to ensure that no local firewall rules prevent
# our neo4j cluser or other services (i.e. samba) from operating normally
#

# call firewall config script

if [ $FIREW == "YES" ] && [ -e $FIREWCONF ]; then
	chmod +x $FIREWCONF
	./$FIREWCONF
	if [ $? -ne 0 ]; then
		echo "script $FIREWCONF returned error code, aborting script"
		echo "ERROR: $FIREWCONF script returned error code." >> $NEOLOG
	fi
else
	echo "failed to locate $FIREWCONF script file, aborting script"
	echo "ERROR: failed to locate $FIREWCONF script file." >> $NEOLOG
fi

#------------------------------------------------
# Setup and configure samba
#------------------------------------------------

#
# Next we need to setup samba so we can load files from windows
# without the need for ssh or ftp.
#

# call samba config script

if [ $SAMBA == "YES" ] && [ -e $SAMBACONF ]; then
	chmod +x $SAMBACONF
	./$SAMBACONF
	if [ $? -ne 0 ]; then
		echo "script $SAMBACONF returned error code, aborting script"
		echo "ERROR: $SAMBACONF script returned error code." >> $NEOLOG
	fi
else
	echo "failed to locate $SAMBACONF script file, aborting script"
	echo "ERROR: failed to locate $SAMBACONF script file." >> $NEOLOG
fi






