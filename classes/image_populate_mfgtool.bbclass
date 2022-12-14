# Allow generation of mfgtool bundle
#
# The class provides the infrastructure for MFGTOOL generation and is tied to images. To generate
# the bundle, the task populate_mfgtool must be called. For example:
#
# ,----[ Running populate_mfgtool for core-image-minimal image ]
# | $: bitbake core-image-minimal -c populate_mfgtool
# `----
#
# The class behavior is controlled through the MFGTOOLSCRIPT variable. The MFGTOOLSCRIPT variable
# itself specifies a space-separated list of the scripts to enable. Following the scripts, you can
# determine the behavior of each script by providing up to two order-dependent arguments, which are
# separated by commas. You can omit any argument you like but must retain the separating commas. The
# order is important and specifies the following:
#
#   1. Extra dependencies that should be added to the do_populate_mfgtool task, if the script is
#      enabled.
#   2. Extra binaries that should be added to the bundle, if the script is enabled.
#
# For example:
#
# ,----[ Defining bootloader.uuu.in script ]
# | MFGTOOLSCRIPT = "bootloader.uuu.in"
# | MFGTOOLSCRIPT[bootloader.uuu.in] = "virtual/bootloader:do_deploy,${UBOOT_BINARY}"
# `----
#
# The virtual/bootloader:do_deploy is added to do_populate_mfgtool dependencies and ${UBOOT_BINARY}
# copied to the bundle, only if the script is enabled.
#
# During the mfgtool bundle generation, the uuu.in files are processed and some variables
# replaced. The variables are:
#
#   - MACHINE
#   - UBOOT_BINARY
#   - SPL_BINARY
#   - IMAGE_BASENAME
#
# Copyright 2022-2023 (C) O.S. Systems Software LTDA.
#
# SPDX-License-Identifier: MIT

MFGTOOL_FILESPATH ??= " \
    ${@base_set_filespath(["%s/mfgtool" % p for p in "${BBPATH}".split(":")] \
                             + ["${FILE_DIRNAME}/${BP}/mfgtool", \
                                "${FILE_DIRNAME}/${BPN}/mfgtool", \
                                "${FILE_DIRNAME}/files/mfgtool"] \
                          , d)} \
"

MFGTOOLDIR = "${WORKDIR}/mfgtool-${PN}"
do_populate_mfgtool[dirs] = "${MFGTOOLDIR}"
do_populate_mfgtool[cleandirs] = "${MFGTOOLDIR}"

addtask populate_mfgtool after do_image_complete do_unpack before do_deploy
do_populate_mfgtool[dirs] ?= "${DEPLOY_DIR_IMAGE} ${WORKDIR}"
do_populate_mfgtool[nostamp] = "1"
do_populate_mfgtool[recrdeptask] += "do_deploy"
do_populate_mfgtool[depends] += "uuu-bin-native:do_populate_sysroot"

python () {
    # Process MFGTOOLSCRIPT and handle its fields.
    mfgtoolscript_flags = d.getVarFlags('MFGTOOLSCRIPT') or {}
    mfgtoolscript_depends = []
    mfgtoolscript_deploy_files = []
    if mfgtoolscript_flags:
        mfgtoolscript = (d.getVar('MFGTOOLSCRIPT') or "").split()
        pn = d.getVar("PN")

        for flag, flagval in sorted(mfgtoolscript_flags.items()):
            items = flagval.split(",")
            num = len(items)
            if num > 2:
                bb.error("%s: MFGTOOLSCRIPT[%s] Only \"depends,deploy files\" can be specified!" % (pn, flag))

            if flag in mfgtoolscript:
                if num >= 2 and items[1]:
                    mfgtoolscript_deploy_files.append(items[1])
                if num >= 1 and items[0]:
                    mfgtoolscript_depends.append(items[0])

        d.appendVarFlag('do_populate_mfgtool', 'depends', ' ' + ' '.join(mfgtoolscript_depends))

    d.setVar('MFGTOOLSCRIPT_DEPLOY_FILES', ' '.join(mfgtoolscript_deploy_files))
}

python do_populate_mfgtool() {
    # For MFGTOOLSCRIPT items we use BitBake's fetcher module allowing a consistent behavior.
    mfgtoolscript = (d.getVar('MFGTOOLSCRIPT') or "").split()
    src_uri = ["file://%s" % f for f in mfgtoolscript]
    if not src_uri:
        bb.fatal("MFGTOOLSCRIPT is empty so populate_mfgtool cannot be run.")
        return
    bb.debug(1, "following script are used: %s" % ', '.join(mfgtoolscript))

    localdata = bb.data.createCopy(d)
    filespath = (d.getVar('MFGTOOL_FILESPATH') or "")
    localdata.setVar('FILESPATH', filespath)

    try:
        fetcher = bb.fetch2.Fetch(src_uri, localdata)
        fetcher.unpack(localdata.getVar('WORKDIR'))
    except bb.fetch2.BBFetchException as e:
        bb.fatal("BitBake Fetcher Error: " + repr(e))

    # Generate MFGTOOL bundle.
    bb.build.exec_func('generate_mfgtool_bundle', d)
}

generate_mfgtool_bundle() {
    bbnote "Processing uuu files ..."
    for src in $(ls -1 ${WORKDIR}/*.uuu.in); do
        dest=$(echo $src | sed 's,.in$,,g')
        bbnote " - $src -> $dest"
        sed -e 's/@@MACHINE@@/${MACHINE}/g' \
            -e "s,@@UBOOT_BINARY@@,${UBOOT_BINARY},g" \
            -e "s,@@SPL_BINARY@@,${SPL_BINARY},g" \
            -e "s,@@IMAGE_BASENAME@@,${IMAGE_BASENAME},g" \
            $src > $dest
    done

    bbnote "Deploying uuu files ..."
    for src in $(ls -1 ${WORKDIR}/*.uuu); do
        dest=$(basename $src)
        bbnote " - $src -> ${MFGTOOLDIR}/${PN}-${MACHINE}/$dest"
        install -D -m 0644 $src ${MFGTOOLDIR}/${PN}-${MACHINE}/$dest
    done

    bbnote "Copying uuu binaries..."
    cp -v -s ${STAGING_LIBDIR_NATIVE}/uuu/* ${MFGTOOLDIR}/${PN}-${MACHINE}/

    bbnote "Copyng MFGTOOL extra deploy files..."
    for f in ${MFGTOOLSCRIPT_DEPLOY_FILES}; do
        mkdir -p ${MFGTOOLDIR}/${PN}-${MACHINE}/binaries
        cp -v -s ${DEPLOY_DIR_IMAGE}/$f ${MFGTOOLDIR}/${PN}-${MACHINE}/binaries/
    done

    tar -czf ${DEPLOY_DIR_IMAGE}/mfgtool-bundle-${PN}-${MACHINE}.tar.gz \
        --dereference -C ${MFGTOOLDIR} ${PN}-${MACHINE}

    ln -fs mfgtool-bundle-${PN}-${MACHINE}.tar.gz \
          ${DEPLOY_DIR_IMAGE}/mfgtool-bundle-${PN}.tar.gz
}
