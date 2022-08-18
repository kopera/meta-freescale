# Released under the MIT license (see COPYING.MIT for the terms)
#
# SPDX-License-Identifier: MIT
#

SUMMARY = "Linux Kernel provided by NXP and supported by Community"
DESCRIPTION = "Linux Kernel provided by NXP as the part of release distribution. \
Main focus is set on i.MX Family Reference Boards. \
It includes support for many NXP Proprietary IPs (GPU, VPU, IPU). \
Latest stable Kernel patchlevel is applied and maintained by Community."

###############################################################################
# This recipe (and corresponding kernel repository and branch) receives updates
# from 3 different sources:
# 1. Stable [linux-5.15.y] branch updates of korg;
# 2. NXP-specific updates via branch [5.10-2.1.x-imx] shared via CodeAurora forum;
# 3. Critical patches, which are not (yet) integrated into either of 2 above
#    sources, but are required to be applied to the kernel tree.
#
# Therefore, there is a need to keep track on the patches which are introduced
# from every source. This could be achieved in this recipe by filling the
# below list with the information once the update is performed from any source.
#
# Once the critical patch gets merged into the stable branch, or NXP-specific
# patches would be covered by the tag - individual entries from sections below
# could be removed.
#
# ------------------------------------------------------------------------------
# 1. Stable (tag or SHA(s))
# ------------------------------------------------------------------------------
#    tag: v5.15.50
#
# ------------------------------------------------------------------------------
# 2. NXP-specific (tag or SHA(s))
# ------------------------------------------------------------------------------
#    tag: lf-5.15.32-2.0.0
#
# ------------------------------------------------------------------------------
# 3. Critical patches (SHA(s))
# ------------------------------------------------------------------------------
# fec_uio: fix implicit declaration
# e8093f50522f cert host tools: Stop complaining about deprecated OpenSSL functions
# 49c2d3b7964d gpio: fix enabling GPIO_VF610
# c04a396fcbf7 ARM: mach-imx: conditionally disable some functions from busfreq-imx
# 166a38557bf9 drm: bridge: it6161: add missing gpio consumer header
# bc2e851e616a Revert "clk: imx: off by one in imx_lpcg_parse_clks_from_dt()"
# 27d3c1285087 Revert "drm/bridge: Add missing pm_runtime_put_sync"
#
# NOTE to upgraders:
# This recipe should NOT collect individual patches, they should be applied to
# the linux-fslc kernel tree on the corresponding branch, and tracking
# information should be properly filled in above.
###############################################################################

include linux-fslc.inc

LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=6bc538ed5bd9a7fc9398086aedcd7e46"

KBRANCH = "5.15-2.0.x-imx"
SRCREV = "d818413e4d7901cb8a00a631a389326e2c93ae41"

# PV is defined in the base in linux-imx.inc file and uses the LINUX_VERSION definition
# required by kernel-yocto.bbclass.
#
# LINUX_VERSION define should match to the kernel version referenced by SRC_URI and
# should be updated once patchlevel is merged.
LINUX_VERSION = "5.15.60"

# Local version indicates the branch name in the NXP kernel tree where patches are collected from.
LOCALVERSION = "-5.15.60-2.0.0"

DEFAULT_PREFERENCE = "1"

COMPATIBLE_MACHINE = "(imx-nxp-bsp)"
