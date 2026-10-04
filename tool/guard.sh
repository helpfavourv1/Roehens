#!/bin/sh
# Roehens guard: structure and style rules from the build specification (Part F).
# Usage: sh tool/guard.sh [--release]
# A source line containing the marker "guard:allow" is exempt from the line-based
# code rules. Credential rules have no exemption.

ROOT=$(cd "$(dirname "$0")/.." && pwd) || exit 2
cd "$ROOT" || exit 2

LIB=app/lib
TEST=app/test
FAILS=$(mktemp)
trap 'rm -f "$FAILS"' EXIT

# Reads grep output (file:line:text) on stdin; ignores comment lines and exempt lines.
check() {
  desc=$1
  out=$(grep -v 'guard:allow' | grep -vE '^[^:]+:[0-9]+:[[:space:]]*(//|/\*|\*)')
  if [ -n "$out" ]; then
    echo x >> "$FAILS"
    echo "GUARD FAIL: $desc"
    echo "$out" | head -n 20
    echo
  fi
}

# Same, but comments and markers do not exempt anything (credential rules).
check_raw() {
  desc=$1
  out=$(cat)
  if [ -n "$out" ]; then
    echo x >> "$FAILS"
    echo "GUARD FAIL: $desc"
    echo "$out" | head -n 20 | cut -c1-160
    echo
  fi
}

dart_grep() {
  grep -rnE --include='*.dart' "$@" 2>/dev/null
}

Q="['\"]"
ID='[^A-Za-z0-9_]'
STOCK='ElevatedButton|TextButton|OutlinedButton|FloatingActionButton|AppBar|BottomNavigationBar|NavigationBar|Card|ListTile|Switch|Checkbox|Radio|Chip|SnackBar|AlertDialog|Drawer|DropdownButton|InkWell|InkResponse|CupertinoButton|CupertinoSwitch|MaterialPageRoute|CupertinoPageRoute'

# C1.1 icons
dart_grep "(^|${ID})(Icons\\.|CupertinoIcons)" $LIB | check "Material or Cupertino icons are forbidden (use AppIcon)"

# C1.2 stock components
dart_grep "(^|[^A-Za-z0-9_.])(${STOCK})(${ID}|\$)" $LIB | check "stock Material/Cupertino component used (use lib/ui/components)"

# C1.10 tokens only
dart_grep 'Color\(0x' $LIB | grep -v '/ui/tokens/' | check "raw Color(0x...) outside lib/ui/tokens"
dart_grep "(^|${ID})Curves\\." $LIB | grep -v 'lib/ui/tokens/motion_tokens.dart:' | check "Curves.* outside motion_tokens.dart"

# C8.3 screens use components, not their own decoration
dart_grep '(BoxDecoration|DecoratedBox)\(' $LIB/screens | check "BoxDecoration/DecoratedBox inside lib/screens"

# numeric literals in layout constructors (heuristic)
dart_grep '(EdgeInsets\.[A-Za-z]+|SizedBox|BorderRadius\.[A-Za-z]+)\(([^)]*[^A-Za-z0-9_.])?[0-9]' $LIB/screens $LIB/widgets | check "numeric literal in EdgeInsets/SizedBox/BorderRadius (use spacing/radius tokens)"

# C1.16 right-to-left safety
dart_grep 'EdgeInsets\.only\([^)]*(left|right)[[:space:]]*:' $LIB | check "EdgeInsets.only(left/right) (use EdgeInsetsDirectional)"
dart_grep 'Alignment\.(centerLeft|centerRight)' $LIB | check "Alignment.centerLeft/centerRight (use AlignmentDirectional)"
dart_grep 'TextDirection\.rtl' $LIB | check "TextDirection.rtl hard-coded"
dart_grep 'TextDirection\.ltr' $LIB | grep -vE '/(ltr_text|app_text_field|help_code_block|app_icon)\.dart:' | check "TextDirection.ltr outside the IP/URL/Mono widgets"

# state management
dart_grep "(^|${ID})setState\\(" $LIB | check "setState( is not allowed (ValueNotifier providers only)"

# unfinished code
dart_grep '(TODO|FIXME|UnimplementedError)' $LIB $TEST | check "TODO/FIXME/UnimplementedError"

# A4 store seam
dart_grep "import ${Q}package:(google_mobile_ads|in_app_purchase|in_app_review)" $LIB | grep -v '^app/lib/platform/store/' | check "store SDK import outside lib/platform/store"

# C4 icon packages
dart_grep "import ${Q}package:[a-z_]*(phosphor|tabler)[a-z_]*/" $LIB | grep -v '^app/lib/ui/icons/app_icons.dart:' | check "icon package import outside lib/ui/icons/app_icons.dart"

# layer rule: core has no dart:io and no plugin imports
dart_grep "^import ${Q}" $LIB/core \
  | grep -vE "import ${Q}(dart:(async|convert|math|typed_data|collection)|package:(roehens|xml|intl|meta|collection|characters)/|package:flutter/foundation\\.dart|[^:'\"]+\\.dart)${Q}" \
  | check "lib/core imports dart:io or a plugin"

# hard-coded user-facing strings in screens and widgets (heuristic)
dart_grep "(^|${ID})Text\\([[:space:]]*${Q}" $LIB/screens $LIB/widgets | check "hard-coded Text string (use localized strings)"
dart_grep "(^|${ID})(semanticLabel|label|hint|title|subtitle|message|tooltip|placeholder)[[:space:]]*:[[:space:]]*${Q}" $LIB/screens $LIB/widgets | check "hard-coded user-facing string (use localized strings)"

# material design flag
grep -nE 'uses-material-design:[[:space:]]*true' app/pubspec.yaml 2>/dev/null | check_raw "uses-material-design must be false"

# C1.15 no SVG filter
for d in app/assets website; do
  if [ -d "$d" ]; then
    grep -rnI '<filter' --include='*.svg' --include='*.html' --include='*.css' "$d" 2>/dev/null | check_raw "<filter> in $d"
  fi
done

# credentials in tracked files
FILES=$(git ls-files 2>/dev/null | grep -v '^tool/guard\.sh$')
if [ -z "$FILES" ]; then
  FILES=$(find . -type f -not -path './.git/*' -not -path '*/build/*' -not -path '*/.dart_tool/*' | sed 's|^\./||' | grep -v '^tool/guard\.sh$')
fi
if [ -n "$FILES" ]; then
  echo "$FILES" | xargs grep -nIE 'github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{30,}|BEGIN [A-Z ]*PRIVATE KEY|MIIK[A-Za-z0-9+/]{60,}|rtsp://[^/@[:space:]]+:[^@[:space:]]+@' 2>/dev/null | check_raw "credential-like string in a tracked file"
  echo "$FILES" | grep -E '\.(dart|kts|gradle|properties|yaml|yml|json|xml|plist|sh)$' \
    | xargs grep -nIiE "(password|passwd|secret|token|apikey|api_key)[[:space:]]*[:=][[:space:]]*[\"'][^\"'\$]{6,}[\"']" 2>/dev/null | check_raw "hard-coded secret assignment in a tracked file"
fi

# end gate: nothing may be waiting for translation
if [ "$1" = "--release" ]; then
  if [ -f l10n_pending.txt ] && grep -vE '^[[:space:]]*(#|$)' l10n_pending.txt | grep -q .; then
    echo x >> "$FAILS"
    echo "GUARD FAIL: l10n_pending.txt is not empty (release gate)"
    echo
  fi
fi

N=$(wc -l < "$FAILS" | tr -d ' ')
if [ "$N" -gt 0 ]; then
  echo "guard: $N rule(s) failed"
  exit 1
fi
echo "guard: all rules passed"
