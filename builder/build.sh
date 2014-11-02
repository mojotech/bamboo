#!/bin/bash
set -e
set -u
name=bamboo
version=${_BAMBOO_VERSION:-"1.0.0"}
description="Bamboo is a DNS based HAProxy auto configuration and auto service discovery for Mesos Marathon."
url="https://github.com/QuBitProducts/bamboo"
arch="all"
section="misc"
license="Apache Software License 2.0"
package_version=${_BAMBOO_PKGVERSION:-"-1"}
origdir="$(pwd)"
workspace="builder"
pkgtype=${_PKGTYPE:-"deb"}
builddir="build"
installdir="opt/${name}"
configdir="etc/${name}"
function cleanup() {
    cd ${origdir}/${workspace}
    rm -rf ${name}*.{deb,rpm}
    rm -rf ${builddir}
}

function bootstrap() {
    cd ${origdir}/${workspace}

    mkdir -p ${builddir}/${name}/${configdir}
    mkdir -p ${builddir}/${name}/${installdir}

    # systemd service directory
    mkdir -p ${builddir}/${name}/usr/lib/systemd/system

    pushd ${builddir}
}

function build() {

    # Prepare binary
    cp ${origdir}/bamboo ${name}/${installdir}/bamboo
    chmod 755 ${name}/${installdir}/bamboo

    # Add default configuration
    cp -p ../bamboo.json ${name}/${configdir}/.

    # Add example configuration
    cp -rp ${origdir}/config/* ${name}/${configdir}/.

    # Add systemd service
    cp -p ../bamboo.service ${name}/usr/lib/systemd/system/.

    # Distribute UI webapp
    mkdir -p ${name}/${installdir}/webapp
    cp -rp ${origdir}/webapp/dist ${name}/${installdir}/webapp/dist
    cp -rp ${origdir}/webapp/fonts ${name}/${installdir}/webapp/fonts
    cp ${origdir}/webapp/index.html ${name}/${installdir}/webapp/index.html

    # Versioning
    echo ${version} > ${name}/${installdir}/VERSION
    pushd ${name}
}

function mkdeb() {
  # rubygem: fpm
  fpm -t ${pkgtype} \
    -n ${name} \
    -v ${version}${package_version} \
    --description "${description}" \
    --url="${url}" \
    -a ${arch} \
    --category ${section} \
    --vendor "Qubit" \
    --after-install ../../build.after-install \
    --after-remove  ../../build.after-remove \
    --before-remove ../../build.before-remove \
    -m "${USER}@${HOSTNAME}" \
    --config-files etc/bamboo \
    --license "${license}" \
    --prefix=/ \
    -s dir \
    -- .
  mv ${name}*.${pkgtype} ${origdir}/${workspace}/
  popd
}

function main() {
    cleanup
    bootstrap
    build
    mkdeb
}

main
