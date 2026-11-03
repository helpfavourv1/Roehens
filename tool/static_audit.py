#!/usr/bin/env python3
"""Whole-repository audit that needs no Flutter SDK.

Checks: import resolution, layer rules, declared versus used packages, asset
files, forbidden tokens, secrets, Android permissions, native channel names,
workflow triggers, and which library files no test reaches. Prints a report and
exits 1 when any error is found. Warnings never fail the run.
"""
import json
import os
import re
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
APP = os.path.join(ROOT, 'app')
LIB = os.path.join(APP, 'lib')
TEST = os.path.join(APP, 'test')

errors = []
warnings = []
notes = []


def err(msg):
    errors.append(msg)


def warn(msg):
    warnings.append(msg)


def rel(path):
    return os.path.relpath(path, ROOT)


def read(path):
    with open(path, encoding='utf-8', errors='replace') as f:
        return f.read()


def dart_files(base):
    out = []
    for d, _, files in os.walk(base):
        for f in files:
            if f.endswith('.dart'):
                out.append(os.path.join(d, f))
    return sorted(out)


IMPORT = re.compile(r"""^\s*(?:import|export)\s+['"]([^'"]+)['"]""", re.M)


def imports_of(path):
    return IMPORT.findall(read(path))


def resolve(path, target):
    """Absolute path of a project import, or None for other packages."""
    if target.startswith('package:roehens/'):
        return os.path.join(LIB, target[len('package:roehens/'):])
    if target.startswith('package:') or target.startswith('dart:'):
        return None
    return os.path.normpath(os.path.join(os.path.dirname(path), target))


lib_files = dart_files(LIB)
test_files = dart_files(TEST)
all_files = lib_files + test_files

# ---------------------------------------------------------------- 1. imports
graph = {}
for f in all_files:
    deps = set()
    for t in imports_of(f):
        r = resolve(f, t)
        if r is None:
            continue
        if not os.path.exists(r):
            err(f'{rel(f)}: import does not resolve: {t}')
        else:
            deps.add(r)
    graph[f] = deps
notes.append(f'{len(lib_files)} library files, {len(test_files)} test files, '
             f'{sum(len(v) for v in graph.values())} project imports resolved')

# ------------------------------------------------------------ 2. layer rules
PLUGIN_ALLOWED_IN_CORE = {'xml', 'intl', 'crypto', 'flutter', 'meta', 'collection'}


def package_of(t):
    m = re.match(r'package:([^/]+)/', t)
    return m.group(1) if m else None


for f in lib_files:
    r = rel(f).replace('\\', '/')
    for t in imports_of(f):
        pkg = package_of(t)
        if r.startswith('app/lib/core/'):
            if t.startswith('dart:') and not re.match(r'dart:(async|convert|math|typed_data|collection|ui)$', t):
                err(f'{r}: core imports {t}')
            if pkg and pkg not in PLUGIN_ALLOWED_IN_CORE and pkg != 'roehens':
                err(f'{r}: core imports plugin package:{pkg}')
        if t.startswith('package:roehens/platform/') and (
                r.startswith('app/lib/widgets/') or r.startswith('app/lib/screens/')
                or r.startswith('app/lib/ui/') or r.startswith('app/lib/core/')):
            err(f'{r}: imports platform/ directly ({t})')
        if r.startswith('app/lib/ui/') and re.match(r'package:roehens/(widgets|screens|platform|core/providers|core/services)/', t):
            err(f'{r}: ui imports upward ({t})')
        if r.startswith('app/lib/platform/') and re.match(r'package:roehens/(widgets|screens|ui)/', t):
            err(f'{r}: platform imports UI ({t})')
        if r.startswith('app/lib/core/') and re.match(r'package:roehens/(widgets|screens|ui|platform)/', t):
            err(f'{r}: core imports {t}')

# --------------------------------------------------------- 3. packages used
pubspec = read(os.path.join(APP, 'pubspec.yaml'))
declared = {}
section = None
for line in pubspec.splitlines():
    if re.match(r'^[a-z_]+:\s*$', line):
        section = line.strip(':').strip()
        continue
    m = re.match(r'^  ([a-z0-9_]+):', line)
    if m and section in ('dependencies', 'dev_dependencies'):
        declared[m.group(1)] = section
used = {}
for f in lib_files:
    for t in imports_of(f):
        p = package_of(t)
        if p and p != 'roehens':
            used.setdefault(p, set()).add('lib')
for f in test_files:
    for t in imports_of(f):
        p = package_of(t)
        if p and p != 'roehens':
            used.setdefault(p, set()).add('test')
SDK = {'flutter', 'flutter_test', 'flutter_localizations', 'flutter_lints'}
for p, where in sorted(used.items()):
    if p not in declared and p not in SDK:
        err(f'package:{p} is imported ({", ".join(sorted(where))}) but not declared in pubspec.yaml')
    elif declared.get(p) == 'dev_dependencies' and 'lib' in where:
        err(f'package:{p} is a dev dependency but used in lib/')
RUNTIME_ONLY = {'media_kit_libs_video', 'cupertino_icons', 'flutter_lints', 'flutter_test',
                'flutter_localizations', 'sqflite_common_ffi'}
for p, kind in sorted(declared.items()):
    if p not in used and p not in RUNTIME_ONLY and p not in SDK:
        warn(f'{p} ({kind}) is declared but never imported')

# ---------------------------------------------------------------- 4. assets
for m in re.finditer(r'^\s+-\s+(assets/[^\s#]+)', pubspec, re.M):
    path = os.path.join(APP, m.group(1))
    if not os.path.exists(path):
        err(f'pubspec asset missing: {m.group(1)}')
for m in re.finditer(r'^\s+-\s+asset:\s+(\S+)', pubspec, re.M):
    if not os.path.exists(os.path.join(APP, m.group(1))):
        err(f'pubspec font asset missing: {m.group(1)}')
if re.search(r'uses-material-design:\s*true', pubspec):
    err('pubspec: uses-material-design is true')

# ---------------------------------------------------- 5. forbidden / tokens
FORBIDDEN = [
    (r'\bTODO\b|\bFIXME\b|UnimplementedError', 'TODO/FIXME/UnimplementedError'),
    (r'\bsetState\(', 'setState'),
    (r'\bprint\(', 'print() in lib'),
    (r'localStorage|sessionStorage', 'browser storage'),
]
for f in lib_files:
    text = read(f)
    for pat, label in FORBIDDEN:
        if label == 'print() in lib' and '/spike/' in f.replace('\\', '/'):
            continue
        if re.search(pat, text):
            err(f'{rel(f)}: contains {label}')
def bracket_balance(text):
    """Counts brackets outside strings and comments, like the Dart scanner."""
    depth = {'(': 0, '[': 0, '{': 0}
    pair = {')': '(', ']': '[', '}': '{'}
    i, n = 0, len(text)
    interp = []  # brace depths at which a string interpolation resumes a string
    while i < n:
        c = text[i]
        two = text[i:i + 2]
        if two == '//':
            while i < n and text[i] != '\n':
                i += 1
            continue
        if two == '/*':
            end = text.find('*/', i + 2)
            i = n if end == -1 else end + 2
            continue
        raw = c == 'r' and i + 1 < n and text[i + 1] in '\'"' and (i == 0 or not (text[i - 1].isalnum() or text[i - 1] == '_'))
        if raw or c in '\'"':
            j = i + 1 if raw else i
            q = text[j]
            triple = text[j:j + 3] == q * 3
            delim = q * 3 if triple else q
            j += len(delim)
            while j < n:
                if not raw and text[j] == '\\':
                    j += 2
                    continue
                if text.startswith(delim, j):
                    j += len(delim)
                    break
                if not raw and text.startswith('${', j):
                    # Skip the interpolated expression, honouring nested braces.
                    k, level = j + 2, 1
                    while k < n and level:
                        if text[k] == '{':
                            level += 1
                        elif text[k] == '}':
                            level -= 1
                        k += 1
                    j = k
                    continue
                if not triple and text[j] == '\n':
                    break
                j += 1
            i = j
            continue
        if c in '([{':
            depth[c] += 1
        elif c in ')]}':
            depth[pair[c]] -= 1
        i += 1
    return depth


for f in lib_files:
    text = read(f)
    if not text.endswith('\n'):
        warn(f'{rel(f)}: no newline at end of file')
    balance = bracket_balance(text)
    if any(balance.values()):
        err(f'{rel(f)}: unbalanced brackets {balance}')

# ---------------------------------------------------------------- 6. secrets
SECRETS = [
    (r'github_pat_[A-Za-z0-9_]{20,}', 'GitHub token'),
    (r'ghp_[A-Za-z0-9]{20,}', 'GitHub token'),
    (r'-----BEGIN [A-Z ]*PRIVATE KEY-----', 'private key'),
    (r'(rtsp|http|https)://[^/\s:@$]+:[^/\s@$]+@', 'URL with credentials'),
    (r'AKIA[0-9A-Z]{16}', 'AWS key'),
    (r'oicp\.net|158\.58\.130\.148|86\.63\.39\.58|24\.134\.3\.9|218\.219\.214\.248|stream\.strba\.sk|176\.139\.87\.16', 'spike stream host'),
]
tracked = subprocess.run(['git', 'ls-files'], cwd=ROOT, capture_output=True, text=True).stdout.split('\n')
SKIP_EXT = ('.png', '.jpg', '.jpeg', '.ttf', '.otf', '.woff', '.woff2', '.jar', '.keystore', '.jks')
for name in tracked:
    if not name or name.endswith(SKIP_EXT) or name == 'tool/static_audit.py':
        continue
    path = os.path.join(ROOT, name)
    if not os.path.isfile(path):
        continue
    text = read(path)
    for pat, label in SECRETS:
        if re.search(pat, text):
            err(f'{name}: possible secret ({label})')
for name in tracked:
    if name.endswith(('.keystore', '.jks', '.p12')):
        err(f'{name}: keystore file is tracked')

# ------------------------------------------------------ 7. Android manifest
manifest_path = os.path.join(APP, 'android/app/src/main/AndroidManifest.xml')
if os.path.exists(manifest_path):
    manifest = read(manifest_path)
    ALLOWED = {'INTERNET', 'ACCESS_NETWORK_STATE', 'ACCESS_WIFI_STATE', 'CHANGE_WIFI_MULTICAST_STATE'}
    for p in re.findall(r'uses-permission[^>]*android:name="android\.permission\.([A-Z_]+)"', manifest):
        if p not in ALLOWED:
            err(f'AndroidManifest: permission {p} is not in the capability matrix')
    for p in ALLOWED:
        if p not in manifest:
            warn(f'AndroidManifest: expected permission {p} is missing')
    if 'allowBackup="false"' not in manifest:
        err('AndroidManifest: allowBackup is not "false"')
    if 'supportsPictureInPicture="true"' not in manifest:
        warn('AndroidManifest: picture-in-picture is not declared')
    notes.append('Android permissions: ' + ', '.join(sorted(set(re.findall(r'android\.permission\.([A-Z_]+)', manifest)))))
else:
    warn('no AndroidManifest.xml found')
gradle = None
for cand in ('android/app/build.gradle.kts', 'android/app/build.gradle'):
    p = os.path.join(APP, cand)
    if os.path.exists(p):
        gradle = read(p)
        break
if gradle:
    for key in ('applicationId', 'namespace', 'minSdk'):
        m = re.search(key + r'\s*=?\s*"?([\w.\.]+)"?', gradle)
        notes.append(f'gradle {key}: {m.group(1) if m else "not found"}')
    if 'com.zdmgold.roehens' not in gradle:
        err('gradle: application id com.zdmgold.roehens not found')

# ------------------------------------------------- 8. native channel names
kt_dir = os.path.join(APP, 'android/app/src/main/kotlin')
kt_channels = set()
for d, _, files in os.walk(kt_dir):
    for f in files:
        if f.endswith('.kt'):
            kt_channels |= set(re.findall(r'"(roehens/[a-z_]+)"', read(os.path.join(d, f))))
dart_channels = set()
for f in lib_files:
    dart_channels |= set(re.findall(r"MethodChannel\(\s*'(roehens/[a-z_]+)'", read(f)))
    dart_channels |= set(re.findall(r"static const String (?:_?channelName|name) = '(roehens/[a-z_]+)'", read(f)))
for c in sorted(kt_channels - dart_channels):
    warn(f'Kotlin channel {c} has no matching Dart channel name (check constants)')
for c in sorted(dart_channels - kt_channels):
    warn(f'Dart channel {c} has no matching Kotlin channel')
notes.append(f'native channels: Kotlin {sorted(kt_channels)}, Dart {sorted(dart_channels)}')

# --------------------------------------------------------- 9. workflows
wf_dir = os.path.join(ROOT, '.github/workflows')
for name in sorted(os.listdir(wf_dir)):
    text = read(os.path.join(wf_dir, name))
    triggers = re.search(r'^on:\n((?:  .*\n|\n)+)', text, re.M)
    block = triggers.group(1) if triggers else ''
    if re.search(r'^\s{2}push:', block, re.M) and name != 'check.yml':
        err(f'workflow {name}: has a push trigger (only check.yml may)')
    if re.search(r'^\s{2}(pull_request|schedule|release|create):', block, re.M):
        err(f'workflow {name}: has an automatic trigger')
    if 'workflow_dispatch' not in block:
        err(f'workflow {name}: is not manually runnable')
    if re.search(r'tags:', block):
        err(f'workflow {name}: has a tag trigger')
    if re.search(r'uses:\s+[^\s@]+@(main|master)\b', text):
        warn(f'workflow {name}: an action is pinned to a moving branch')
    if re.search(r'flutter-version:\s*[\'"]?(stable|latest)', text):
        err(f'workflow {name}: Flutter version is not pinned')
versions = set()
for name in os.listdir(wf_dir):
    versions |= set(re.findall(r"flutter-version:\s*'([^']+)'", read(os.path.join(wf_dir, name))))
if len(versions) > 1:
    err(f'workflows pin different Flutter versions: {sorted(versions)}')
notes.append(f'workflows: {sorted(os.listdir(wf_dir))}, Flutter pins: {sorted(versions)}')

# ------------------------------------------------ 10. what the tests reach
direct = set()
for f in test_files:
    direct |= graph[f]
reach = set(direct)
frontier = list(direct)
while frontier:
    cur = frontier.pop()
    for d in graph.get(cur, ()):
        if d not in reach:
            reach.add(d)
            frontier.append(d)
unreached = [f for f in lib_files if f not in reach]
entry = {os.path.join(LIB, 'main.dart')}
for f in unreached:
    r = rel(f).replace('\\', '/')
    if f in entry or '/spike/' in r:
        continue
    warn(f'no test reaches {r}')
unused = []
imported_by = {}
for f, deps in graph.items():
    for d in deps:
        imported_by.setdefault(d, set()).add(f)
for f in lib_files:
    r = rel(f).replace('\\', '/')
    if '/spike/' in r or f in entry:
        continue
    if f not in imported_by:
        unused.append(r)
for r in unused:
    warn(f'not imported by any other file yet: {r}')

# --------------------------------------------------------------- 11. docs
for d in ('IDENTITY.md', 'DECISIONS.md', 'ICON_MAP.md', 'VISUAL_QA.md'):
    if not os.path.exists(os.path.join(ROOT, 'docs', d)):
        err(f'docs/{d} is missing')
if not os.path.exists(os.path.join(ROOT, 'app/pubspec.lock')):
    err('app/pubspec.lock is not committed')

# --------------------------------------------------------------- report
print('== static audit')
for n in notes:
    print('note:    ', n)
for w in warnings:
    print('warning: ', w)
for e in errors:
    print('ERROR:   ', e)
print(f'== {len(errors)} error(s), {len(warnings)} warning(s)')
sys.exit(1 if errors else 0)
