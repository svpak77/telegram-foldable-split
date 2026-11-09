#!/usr/bin/env bash
# Build the patched APK inside Docker. Adjust IMAGE / paths for your machine.
set -uo pipefail
IMAGE=${IMAGE:-tgfork-build}
SRC=${SRC:-$HOME/projects/tg-fork}
GRADLE_HOME=${GRADLE_HOME:-$HOME/projects/tg-build-home/gradle}
mkdir -p "$GRADLE_HOME" "$SRC/out"

docker run --rm --network=host \
  -v "$SRC":/src -v "$GRADLE_HOME":/home/gradle -e GRADLE_USER_HOME=/home/gradle \
  "$IMAGE" bash -lc '
    set -e
    cd /src
    git config --global --add safe.directory /src
    gradle --parallel -Parm64-v8a :TMessagesProj_App:assembleAfatRelease --stacktrace
  '
rc=$?
cp -v "$SRC"/TMessagesProj_App/build/outputs/apk/afat/release/*.apk "$SRC/out/" 2>/dev/null
ls -lh "$SRC/out"
exit $rc
