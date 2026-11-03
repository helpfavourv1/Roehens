#!/bin/sh
# Lists the license of every package in the resolved dependency set and fails on
# a disallowed class (GPL, AGPL). LGPL and unknown licenses are reported for a
# manual decision. Run after `flutter pub get` (needs .dart_tool/package_config.json).
# Usage: sh tool/license_audit.sh
set -eu
HERE=$(cd "$(dirname "$0")/.." && pwd)
CONFIG="$HERE/app/.dart_tool/package_config.json"
[ -f "$CONFIG" ] || { echo "run 'flutter pub get' in app/ first"; exit 2; }
python3 - "$CONFIG" <<'PY'
import json, os, re, sys

config_path = sys.argv[1]
with open(config_path) as f:
    config = json.load(f)
base = os.path.dirname(config_path)

def classify(text):
    t = re.sub(r'\s+', ' ', text)
    if re.search(r'GNU AFFERO GENERAL PUBLIC', t, re.I):
        return 'AGPL'
    if re.search(r'GNU LESSER GENERAL PUBLIC', t, re.I):
        return 'LGPL'
    if re.search(r'GNU GENERAL PUBLIC LICENSE', t, re.I):
        return 'GPL'
    if re.search(r'Mozilla Public License', t, re.I):
        return 'MPL-2.0'
    if re.search(r'Apache License', t, re.I):
        return 'Apache-2.0'
    if re.search(r'Permission to use, copy, modify, and/or distribute', t, re.I):
        return 'ISC'
    if re.search(r'Redistribution and use in source and binary forms', t, re.I):
        return 'BSD'
    if re.search(r'Permission is hereby granted, free of charge', t, re.I):
        return 'MIT'
    if re.search(r'Unlicense|public domain', t, re.I):
        return 'Unlicense'
    return 'UNKNOWN'

ALLOWED = {'MIT', 'BSD', 'Apache-2.0', 'ISC', 'MPL-2.0', 'Unlicense'}
rows = []
for pkg in sorted(config['packages'], key=lambda p: p['name']):
    name = pkg['name']
    if name == 'roehens':
        continue
    root = pkg['rootUri']
    path = os.path.normpath(os.path.join(base, root[len('file://'):] if root.startswith('file://') else root))
    found = None
    if os.path.isdir(path):
        for cand in sorted(os.listdir(path)):
            if re.match(r'(LICEN[CS]E|COPYING|UNLICENSE)', cand, re.I) and os.path.isfile(os.path.join(path, cand)):
                found = os.path.join(path, cand)
                break
    kind = classify(open(found, errors='replace').read()) if found else 'NO LICENSE FILE'
    rows.append((name, kind))

width = max(len(n) for n, _ in rows)
counts = {}
for name, kind in rows:
    counts[kind] = counts.get(kind, 0) + 1
    flag = '' if kind in ALLOWED else '   <-- review'
    print(f'{name.ljust(width)}  {kind}{flag}')
print()
print('summary:', ', '.join(f'{k}: {v}' for k, v in sorted(counts.items())))
bad = [n for n, k in rows if k in ('GPL', 'AGPL')]
review = [(n, k) for n, k in rows if k not in ALLOWED and k not in ('GPL', 'AGPL')]
if review:
    print('needs a manual decision:', ', '.join(f'{n} ({k})' for n, k in review))
if bad:
    print('DISALLOWED:', ', '.join(bad))
    sys.exit(1)
print('license audit: no GPL or AGPL package')
PY
