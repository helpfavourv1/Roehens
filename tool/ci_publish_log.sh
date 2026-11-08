#!/bin/sh
# Publishes the log of the current CI run to the orphan branch "ci-logs" (file latest.log)
# so the build agent can read it. Needs GH_TOKEN and the standard GITHUB_* variables.
# If SCREENSHOT_DIR names a folder with .png files, they are published next to the
# log (folder screenshots/), so the agent can look at what the app drew.
# Usage: sh tool/ci_publish_log.sh <log-file> <workflow-title>
set -eu
LOG=${1:?log file}
TITLE=${2:-ci}
WORK=$(mktemp -d)
{
  echo "workflow: $TITLE"
  echo "run: ${GITHUB_RUN_ID:-local}"
  echo "sha: ${GITHUB_SHA:-unknown}"
  echo "job status: ${JOB_STATUS:-unknown}"
  echo
  if [ -f "$LOG" ]; then tail -c 300000 "$LOG"; else echo "(no log produced)"; fi
} > "$WORK/latest.log"
if [ -n "${SCREENSHOT_DIR:-}" ] && ls "$SCREENSHOT_DIR"/*.png > /dev/null 2>&1; then
  mkdir -p "$WORK/screenshots"
  cp "$SCREENSHOT_DIR"/*.png "$WORK/screenshots/"
fi
cd "$WORK"
git init -q -b ci-logs
git config user.name "github-actions"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git add -A
git commit -q -m "ci log: $TITLE ${GITHUB_RUN_ID:-local}"
git push -q -f "https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" ci-logs
