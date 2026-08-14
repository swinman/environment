#!/bin/sh
#
# config_arm.sh - the Arm bare metal toolchain, openocd and J-Link.

# to run this dd below line (minus #) into "r, then use @r
#! chmod 755 %; %
# to run a line individually, do the above, but yy instead of dd
# 0i! <Esc>"ryy@ruu

SETUPDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
ENVDIR=${ENVDIR:-$(CDPATH= cd -- "$SETUPDIR/.." && pwd -P)}
. "$SETUPDIR/config_common.sh"
start_log "$@"

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #
get_packages() {
    echo "Getting embedded development packages"
    sudo apt-get install openocd -y
    sudo apt-get install gtkterm -y
}

# SEGGER's J-Link software.
#
# SEGGER serve their downloads behind a licence form, and the field posted
# below is that form's accept box: running this agrees to SEGGER's terms
# exactly as clicking through the download page does.  The unversioned URL
# always serves the current release.
#
# The package brings its own /etc/udev/rules.d/99-jlink.rules and symlinks
# JLinkExe into /usr/bin, so there is no rule to place and no PATH entry to
# add here.
JLINK_URL="https://www.segger.com/downloads/jlink"

get_jlink() {
    [ "$OS" = "linux" ] || return 0

    if command -v JLinkExe >/dev/null 2>&1; then
        echo "JLink present: $(dpkg-query -W -f='${Version}' jlink 2>/dev/null)"
        return 0
    fi

    case "$(uname -m)" in
        x86_64) _gj_arch=x86_64 ;;
        aarch64) _gj_arch=arm64 ;;
        *)
            echo "  WARNING: SEGGER publish no J-Link build for $(uname -m)" >&2
            return 1
            ;;
    esac

    command -v curl >/dev/null 2>&1 || sudo apt-get install curl -y

    _gj_tmp=$(mktemp -d)
    # apt reads a local .deb as the _apt user and warns when it cannot reach
    # the directory holding it; mktemp -d is 0700.
    chmod 755 "$_gj_tmp"
    echo "Fetching J-Link (accepting SEGGER's licence, see $JLINK_URL)"
    if ! curl -fSL --progress-bar -o "$_gj_tmp/jlink.deb" \
            -X POST -d 'accept_license_agreement=accepted' \
            "$JLINK_URL/JLink_Linux_$_gj_arch.deb"; then
        echo "  WARNING: J-Link download failed" >&2
        rm -rf "$_gj_tmp"
        return 1
    fi

    # apt-get, not dpkg -i: the package depends on two dozen X libraries and
    # dpkg would leave every one of them unresolved.
    if ! sudo apt-get install -y "$_gj_tmp/jlink.deb"; then
        echo "  WARNING: J-Link install failed" >&2
        rm -rf "$_gj_tmp"
        return 1
    fi
    rm -rf "$_gj_tmp"
    echo "  installed J-Link $(dpkg-query -W -f='${Version}' jlink 2>/dev/null)"
}


# The Arm GNU Toolchain, from Arm's gitlab package registry.
#
# That registry is where Arm publishes now.  The older
# developer.arm.com/-/media/Files/downloads/gnu/ paths still serve releases up
# to 15.2 but 404 on anything current.
ARM_TOOLCHAIN_API="https://gitlab.arm.com/api/v4/projects/tooling%2Fgnu-toolchains-for-arm/packages"
ARM_TOOLCHAIN_URL="$ARM_TOOLCHAIN_API/generic/gnu-toolchain"

# Only reached when the registry cannot be, so that an offline machine still
# installs something rather than nothing.
ARM_TOOLCHAIN_VER=${ARM_TOOLCHAIN_VER:-15.3.rel1}

# The newest release the registry holds.
#
# The filter is what keeps this honest.  Alongside the releases the registry
# carries betas and the mpacbti branch - 12.2.mpacbti-bet1, 12.2.mpacbti-rel1 -
# and taking the top of an unfiltered sort would hand back a beta on the day
# one is published for a new major.  Requiring a plain <major>.<minor>.rel<n>
# also drops the 11.2-2022.02 that predates the naming.
#
# sort -V rather than the API's own order_by=version: that ordering is
# undocumented for versions this shape, and getting it wrong is silent.
arm_latest_version() {
    curl -sf "$ARM_TOOLCHAIN_API?per_page=100" 2>/dev/null |
        grep -o '"version":"[^"]*"' | cut -d'"' -f4 |
        grep -E '^[0-9]+\.[0-9]+\.[Rr]el[0-9]+$' |
        sort -Vr | head -1
}

get_gcc_arm() {
    [ "$OS" = "linux" ] || return 0

    _ga_dir="$toolsdir/arm-none-eabi"
    # The release this script last unpacked here.  arm-none-eabi-gcc
    # -dumpversion answers with the compiler version (15.3.0), not the release
    # it came out of (15.3.rel1), so the release has to be recorded rather
    # than read back off the toolchain.
    _ga_stamp="$_ga_dir/.toolchain-release"

    _ga_ver=$(arm_latest_version)
    if [ -z "$_ga_ver" ]; then
        _ga_ver=$ARM_TOOLCHAIN_VER
        echo "  registry unreachable, falling back to $_ga_ver"
    fi

    if [ -f "$_ga_stamp" ] && [ "$(cat "$_ga_stamp")" = "$_ga_ver" ]; then
        echo "arm-none-eabi $_ga_ver present"
        return 0
    fi

    case "$(uname -m)" in
        x86_64) _ga_arch=x86_64 ;;
        aarch64) _ga_arch=aarch64 ;;
        *)
            echo "  WARNING: Arm publishes no toolchain for $(uname -m)" >&2
            return 1
            ;;
    esac

    command -v curl >/dev/null 2>&1 || sudo apt-get install curl -y
    command -v xz >/dev/null 2>&1 || sudo apt-get install xz-utils -y

    _ga_name="arm-gnu-toolchain-$_ga_ver-$_ga_arch-arm-none-eabi"
    _ga_tmp=$(mktemp -d)
    echo "Fetching $_ga_name"
    if ! curl -fSL --progress-bar -o "$_ga_tmp/tc.tar.xz" \
            "$ARM_TOOLCHAIN_URL/$_ga_ver/$_ga_name.tar.xz"; then
        echo "  WARNING: download failed, no arm-none-eabi toolchain" >&2
        rm -rf "$_ga_tmp"
        return 1
    fi

    # Only now that the tarball is in hand, so a failed download leaves the
    # working toolchain where it was.  A stamped tree is one this script
    # unpacked and can fetch again, so it goes; an unstamped one came from
    # somewhere else - this machine carried a 2017 Atmel 6.3.1 build - and is
    # moved aside instead of being thrown away on its owner's behalf.
    if [ -d "$_ga_dir" ]; then
        if [ -f "$_ga_stamp" ]; then
            echo "Replacing $(cat "$_ga_stamp")"
            rm -rf "$_ga_dir"
        else
            echo "Retiring the toolchain already at $_ga_dir"
            retire_path "$_ga_dir" "$toolsdir/unused"
        fi
    fi

    # --strip-components=1 drops the tarball's versioned top level, so the
    # tools land at $toolsdir/arm-none-eabi/bin - the one path _aliases puts
    # on PATH, whatever version is installed under it.
    echo "Extracting to $_ga_dir"
    mkdir -p "$_ga_dir"
    if ! tar -xJf "$_ga_tmp/tc.tar.xz" -C "$_ga_dir" --strip-components=1; then
        echo "  WARNING: extract failed" >&2
        rm -rf "$_ga_tmp" "$_ga_dir"
        return 1
    fi
    rm -rf "$_ga_tmp"
    echo "$_ga_ver" > "$_ga_stamp"
    echo "  installed $_ga_ver, gcc $("$_ga_dir/bin/arm-none-eabi-gcc" -dumpversion)"
}

# --------------------- SETUP SCRIPT --------------------- #
echo "==================== config_arm.sh  ===================="
if [ "$OS" = "linux" ]; then
    get_packages;
fi

rc=0
get_gcc_arm || rc=1
get_jlink || rc=1

echo "=============== END: config_arm.sh  ===================="
exit $rc
