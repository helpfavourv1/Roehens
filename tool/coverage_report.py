#!/usr/bin/env python3
"""Summarizes app/coverage/lcov.info: percentage per folder, and the files with
the lowest coverage. Informational; it never fails the run."""
import os
import sys

path = sys.argv[1] if len(sys.argv) > 1 else 'app/coverage/lcov.info'
if not os.path.exists(path):
    print('no coverage file at', path)
    sys.exit(0)

files = {}
current = None
for line in open(path):
    line = line.strip()
    if line.startswith('SF:'):
        current = line[3:]
        files[current] = [0, 0]
    elif line.startswith('LF:') and current:
        files[current][0] = int(line[3:])
    elif line.startswith('LH:') and current:
        files[current][1] = int(line[3:])

def pct(found, hit):
    return 100.0 * hit / found if found else 100.0

folders = {}
for name, (found, hit) in files.items():
    parts = name.split('/')
    key = '/'.join(parts[:2]) if len(parts) > 2 else parts[0]
    f, h = folders.get(key, (0, 0))
    folders[key] = (f + found, h + hit)

total_f = sum(v[0] for v in files.values())
total_h = sum(v[1] for v in files.values())
print('== coverage by folder')
for key in sorted(folders):
    f, h = folders[key]
    print(f'{key.ljust(28)} {pct(f, h):5.1f}%  ({h}/{f} lines)')
print(f'{"TOTAL".ljust(28)} {pct(total_f, total_h):5.1f}%  ({total_h}/{total_f} lines)')

print()
print('== lowest covered files (under 60%, at least 20 lines)')
low = sorted(
    ((pct(f, h), n, h, f) for n, (f, h) in files.items() if f >= 20 and pct(f, h) < 60),
)
for p, n, h, f in low[:25]:
    print(f'{p:5.1f}%  {n}  ({h}/{f})')
if not low:
    print('none')
