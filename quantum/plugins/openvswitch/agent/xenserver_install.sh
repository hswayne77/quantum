#!/bin/bash

set -x

#CONF_FILE=/etc/xapi.d/plugins/ovs_quantum_plugin.ini
CONF_FILE=/etc/quantum/plugins/ovs_quantum_plugin.ini
#VERSION=$(python -c "import sys,os ; sys.path.append('../../../../quantum/') ; import version ; os.chdir('../../../../'); print version.version_info.canonical_version_string()")
VERSION=2013.1

# install EPEL package
# --------------------
rpm -Uvh http://dl.fedoraproject.org/pub/epel/5/i386/epel-release-5-4.noarch.rpm
# install python-sqlalchemy MySQL-python
if [ "$1" == "with_python_2.6" ] ; then
    yum --enablerepo=base -y install mx
    yum --enablerepo=epel -y install python26 python26-sqlalchemy python26-mysqldb
else
    yum --enablerepo=epel -y install python-sqlalchemy
    yum --enablerepo=base -y install MySQL-python
fi
sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/epel.repo


# install ovs-quantum-agent rpm package
# --------------------------------------
RPM_FILE=ovs-quantum-agent-${VERSION}-1.noarch.rpm
if [[ $(rpm -qa 'ovs-quantum-agent') =~ '*quantum-agent*' ]];then
    rpm -e ${RPM_FILE}
fi
rpm -Uvh ../ovs_quantum_agent/build/rpm/RPMS/noarch/${RPM_FILE}

# create integration bridge
# -------------------------
xe network-list name-label="br-int" | grep xapi >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "No integration bridge found.  Creating."
    xe network-create name-label="br-int"
fi

# copy quantum config
# -------------------
QCFG=/etc/quantum
cp ../../../../etc/quantum.conf ${QCFG}
cp -r ../../../../etc/quantum/ ${QCFG}


# ovs_quantum_plugin config setting
# ---------------------------------
BR=$(xe network-list --minimal name-label="br-int" params=bridge)
CONF_BR=$(grep integration-bridge ${CONF_FILE} | cut -d= -f2)
if [ "X$BR" != "X$CONF_BR" ]; then
    echo "Integration bridge doesn't match configuration file; fixing."
    sed -i -e "s/^integration-bridge =.*$/integration-bridge = ${BR}/g" $CONF_FILE
fi
echo "Using integration bridge: $BR (make sure this is set in the nova configuration)"
echo "Make sure to edit: $CONF_FILE"

