#!/bin/zsh
set -euo pipefail

PROJECT_ROOT="${0:A:h:h}"
SOURCE_APP="$PROJECT_ROOT/build/MenuFold.app"
DESTINATION_APP="/Applications/MenuFold.app"

if [[ ! -d "$SOURCE_APP" ]]; then
    print -u2 "Build MenuFold first: $PROJECT_ROOT/scripts/build-app.sh"
    exit 1
fi

pkill -x MenuFold 2>/dev/null || true
rm -rf "$DESTINATION_APP"
ditto "$SOURCE_APP" "$DESTINATION_APP"
open "$DESTINATION_APP"

print "$DESTINATION_APP"
