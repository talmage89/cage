#!/usr/bin/env bash

# Apply network firewall if a restricted profile is configured.
# "full" and unset mean no restrictions; "none" is handled at the
# Docker level (--network none) and never reaches here.

if [[ -n "${CAGE_NETWORK_PROFILE:-}" && "$CAGE_NETWORK_PROFILE" != "full" ]]; then
    sudo /etc/cage-network/apply-firewall.sh "$CAGE_NETWORK_PROFILE"
fi

# Worktree support: copy the main repo's .git directory into the
# tmpfs overlay so git works inside the container.
if [[ -n "${CAGE_WORKTREE:-}" && -d "/tmp/.host-git-dir" ]]; then
    cp -a /tmp/.host-git-dir/. /workspace/.git/
    # Use the worktree's own HEAD and index instead of the main repo's
    wt="/workspace/.git/worktrees/$CAGE_WORKTREE"
    if [[ -d "$wt" ]]; then
        cp -f "$wt/HEAD" /workspace/.git/HEAD
        [[ -f "$wt/index" ]] && cp -f "$wt/index" /workspace/.git/index
    fi
fi

# Fix ownership on cached dir volumes (Docker creates them as root)
if [[ -n "${CAGE_CACHED_DIRS:-}" ]]; then
    for dir in $CAGE_CACHED_DIRS; do
        [[ -d "/workspace/$dir" ]] && sudo chown cage:cage "/workspace/$dir"
    done
fi

exec "$@"
