#!/bin/sh
# Waits for a CI run and prints its result. Needs GH_TOKEN in the environment
# (the owner's access token; never write it into the repo).
#
#   sh tool/ci_wait.sh check <short-sha>      wait for the push check of a commit, print the log summary
#   sh tool/ci_wait.sh run   <workflow.yml>   wait for the newest run of a manual workflow
#
# The check workflow publishes its log to the ci-logs branch (latest.log); the
# emulator_check workflow also publishes screenshots there (screenshots/*.png).
# The branch is replaced by the next run, so read it straight after the run ends.
set -eu
REPO="helpfavourv1/Roehens"
API="https://api.github.com/repos/$REPO"
AUTH="Authorization: Bearer ${GH_TOKEN:?set GH_TOKEN}"
mode="${1:?check|run}"
arg="${2:?sha or workflow file}"

summary() {
  sleep 12
  curl -s -H "$AUTH" -H "Accept: application/vnd.github.raw" "$API/contents/latest.log?ref=ci-logs" > /tmp/ci.log
  python3 - <<'PY'
t = open('/tmp/ci.log', encoding='utf-8', errors='replace').read().splitlines()
keys = ('error •', 'warning •', 'info •', 'No issues', 'guard:', 'tests passed', 'issues found',
        'Some tests', 'All tests passed', 'VERDICT')
for i, l in enumerate(t):
    if any(k in l for k in keys):
        print(i, l[:300])
PY
}

if [ "$mode" = check ]; then
  for i in $(seq 1 12); do
    r=$(curl -s -H "$AUTH" "$API/actions/runs?per_page=8" | python3 -c "
import sys, json
runs = [x for x in json.load(sys.stdin)['workflow_runs'] if x['head_sha'].startswith('$arg') and x['name'] == 'check']
print((runs[0]['status'], runs[0]['conclusion']) if runs else 'none')")
    echo "$i $r"
    case "$r" in *completed*) break;; esac
    sleep 20
  done
  summary
else
  sleep 30
  id=$(curl -s -H "$AUTH" "$API/actions/workflows/$arg/runs?per_page=1" | python3 -c "import sys, json; print(json.load(sys.stdin)['workflow_runs'][0]['id'])")
  for i in $(seq 1 9); do
    r=$(curl -s -H "$AUTH" "$API/actions/runs/$id" | python3 -c "import sys, json; r = json.load(sys.stdin); print(r['status'], r['conclusion'])")
    echo "$i run $id: $r"
    case "$r" in completed*) break;; esac
    sleep 28
  done
fi
