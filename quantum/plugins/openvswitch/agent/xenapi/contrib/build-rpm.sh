#!/bin/bash

set -eux

# install packages for rpm-build 
pip install pbr
yum --enablerepo=base install -y rpm-build

thisdir=$(dirname $(readlink -f "$0"))
export QUANTUM_ROOT="$thisdir/../../../../../../"
export PYTHONPATH=$QUANTUM_ROOT


cd $QUANTUM_ROOT
VERSION=$(python -c "import sys,os; sys.path.append('"${QUANTUM_ROOT}"/quantum'); import version; print version.version_info.canonical_version_string()")


cd -

PACKAGE=openstack-quantum-xen-plugins
RPMBUILD_DIR=${PWD}/rpmbuild
if [ ! -d ${RPMBUILD_DIR} ]; then
    echo ${RPMBUILD_DIR} is missing
    exit 1
fi

for dir in BUILD BUILDROOT SRPMS RPMS SOURCES; do
    rm -rf $RPMBUILD_DIR/$dir
    mkdir -p $RPMBUILD_DIR/$dir
done

rm -rf /tmp/$PACKAGE
mkdir /tmp/$PACKAGE
cp -r ../etc/xapi.d /tmp/$PACKAGE
tar czf $RPMBUILD_DIR/SOURCES/$PACKAGE.tar.gz -C /tmp $PACKAGE

rpmbuild -ba --nodeps \
         --define "_topdir $RPMBUILD_DIR" \
         --define "version $VERSION" \
         $RPMBUILD_DIR/SPECS/$PACKAGE.spec
