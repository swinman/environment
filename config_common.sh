# config_common.sh - helpers shared by the config_*.sh scripts.
#
# Sourced, not executed:
#
#     ENVDIR=${ENVDIR:-$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)}
#     . "$ENVDIR/config_common.sh"
#
# $ENVDIR is normally exported by config_shell.sh.  Scripts fall back to their
# own directory so each stays runnable on its own before config_shell.sh has
# been run for the first time on a new machine.  That fallback replaced the
# older habit of deriving paths from $0 or ${BASH_SOURCE[0]} at each use site.

# link_config <path-relative-to-ENVDIR> <destination>
#
# Point a destination at a file or directory in the repo, so it tracks the repo
# instead of being a copy.  Anything real already at the destination is backed
# up rather than clobbered.
link_config() {
    _lc_src="$ENVDIR/$1"
    _lc_dst="$2"

    if [ ! -e "$_lc_src" ]; then
        echo "  WARNING: $_lc_src missing in repo, skipping $_lc_dst"
        return 1
    fi

    if [ -L "$_lc_dst" ]; then
        # Compare the target rather than just testing "is a symlink": a link
        # left over from an older layout should be repaired, not kept.
        if [ "$(readlink "$_lc_dst")" = "$_lc_src" ]; then
            echo "  $_lc_dst already linked"
            return 0
        fi
        echo "  relinking $_lc_dst (was $(readlink "$_lc_dst"))"
        rm -f "$_lc_dst"
    elif [ -e "$_lc_dst" ]; then
        _lc_bak="$_lc_dst.bak.$(date +%Y%m%d%H%M%S)"
        mv "$_lc_dst" "$_lc_bak"
        echo "  backed up $_lc_dst -> $_lc_bak"
    fi

    ln -s "$_lc_src" "$_lc_dst"
    echo "  linked $_lc_dst -> $_lc_src"
}

# retire_path <path> <graveyard-directory>
#
# Move something obsolete out of the way instead of deleting it, so a bad
# guess about what is still wanted is recoverable.
retire_path() {
    [ -e "$1" ] || return 0
    mkdir -p "$2"
    _rp_dst="$2/$(basename "$1")"
    if [ -e "$_rp_dst" ]; then
        _rp_dst="$_rp_dst.$(date +%Y%m%d%H%M%S)"
    fi
    mv "$1" "$_rp_dst"
    echo "  moved $1 aside to $_rp_dst"
}

# clone_or_pull <url> <directory>
#
# Fetch a repo, or bring an existing checkout up to date.  --ff-only so a
# checkout that has somehow diverged fails loudly instead of quietly growing a
# merge commit in someone else's repository.
clone_or_pull() {
    _cp_url="$1"
    _cp_dir="$2"
    _cp_name=$(basename "$_cp_dir")

    if [ -d "$_cp_dir/.git" ]; then
        echo "  updating $_cp_name"
        git -C "$_cp_dir" pull --ff-only --quiet ||
            echo "  WARNING: pull failed in $_cp_dir - diverged or dirty?"
    elif [ -e "$_cp_dir" ]; then
        echo "  WARNING: $_cp_dir exists but is not a git checkout, leaving it"
    else
        echo "  cloning $_cp_name"
        git clone --quiet "$_cp_url" "$_cp_dir"
    fi
}

# vim:ft=sh
