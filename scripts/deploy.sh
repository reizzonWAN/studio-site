#!/usr/bin/env bash
# Run on your own machine: publish the release/prod branch to the VPS, where the shared edge Caddy serves it
# (edge repo "caddy", sites/studio.caddy, mounted read-only at /srv/studio-site).
#
# Usage: scripts/deploy.sh deploy@<server-ip>
#        SSH_PORT=2222 scripts/deploy.sh deploy@<server-ip>
#
# What is published is exactly what has been pushed to origin/release/prod, exported with `git archive`.
# Uncommitted or unpushed local changes are never shipped. Caddy serves straight from disk, so no reload.
#
# Emergency override (a hotfix not yet on release/prod): DEPLOY_REF=<commit-or-ref>.
set -euo pipefail

target="${1:?usage: scripts/deploy.sh deploy@<server-ip>}"
ssh_port="${SSH_PORT:-22}"
root="$(cd "$(dirname "$0")/.." && pwd)"
release_branch=release/prod
ref="${DEPLOY_REF:-origin/$release_branch}"
site_dir=/opt/sites/studio-site

rsync_bin="${RSYNC:-}"
for candidate in /opt/homebrew/bin/rsync /usr/local/bin/rsync rsync; do
	[[ -n "$rsync_bin" ]] && break
	command -v "$candidate" >/dev/null && rsync_bin="$candidate"
done
[[ -n "$rsync_bin" ]] || {
	echo "rsync not found" >&2
	exit 1
}

echo "Fetching origin"
git -C "$root" fetch --quiet origin
revision="$(git -C "$root" rev-parse --verify --quiet "$ref^{commit}")" || {
	echo "Cannot resolve $ref. Has $release_branch been pushed?" >&2
	exit 1
}
if [[ -n "${DEPLOY_REF:-}" ]]; then
	echo "WARNING: deploying $DEPLOY_REF instead of $release_branch. Merge it into $release_branch afterwards." >&2
fi

export_dir="$(mktemp -d)"
trap 'rm -rf "$export_dir"' EXIT
git -C "$root" archive --format=tar "$revision" | tar -x -C "$export_dir"
# Repo-only files are not part of the site.
rm -rf "$export_dir/scripts" "$export_dir/README.md" "$export_dir/.gitignore"
printf '%s %s\n' "$revision" "$(git -C "$root" log -1 --format=%s "$revision")" >"$export_dir/REVISION"
# The edge container reads the files as a non-root user: make everything world-readable.
chmod -R a+rX "$export_dir"

echo "Publishing $ref ($(git -C "$root" rev-parse --short "$revision")) → $target:$site_dir"
ssh -p "$ssh_port" "$target" "test -d $site_dir" || {
	echo "$site_dir is missing on the server (see README: first-time setup)" >&2
	exit 1
}
"$rsync_bin" -rlptz --delete -e "ssh -p $ssh_port" "$export_dir/" "$target:$site_dir/"
echo "Published. Check: curl -sSI https://onlinebuildstudio.com/"
