#!/usr/bin/env bash
# Reproducible HAP build check.
# Usage: DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk ./scripts/verify-build.sh
set -euo pipefail

: "${DEVECO_SDK_HOME:?Set DEVECO_SDK_HOME to the installed HarmonyOS SDK root}"

DEVECO_APP="${DEVECO_APP:-/Applications/DevEco-Studio.app}"
HVIGOR="$DEVECO_APP/Contents/tools/hvigor/bin/hvigorw"

cd "$(dirname "$0")/.."

"$HVIGOR" --mode module -p product=default assembleHap

echo "HAP output:"
ls -l entry/build/default/outputs/default/
