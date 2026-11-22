#!/bin/bash
# Linux IPA build: same approach as AppForge / grokbot (clang + iOS SDK + ldid).
# On GitHub Actions, THEOS is set and provides the toolchain + SDK.
# Locally, /workspace/iostc is used if present.
set -euo pipefail
cd "$(dirname "$0")"
. ./app.cfg
if [ -n "${THEOS:-}" ] && [ -d "${THEOS}/toolchain/linux/iphone/bin" ]; then
  TC="${TC:-${THEOS}/toolchain/linux/iphone/bin}"
  if [ -d "${THEOS}/sdks/iPhoneOS16.5.sdk" ]; then
    SDK="${SDK:-${THEOS}/sdks/iPhoneOS16.5.sdk}"
  fi
fi
TC="${TC:-/workspace/iostc/linux/iphone/bin}"
SDK="${SDK:-/workspace/iostc/iPhoneOS16.5.sdk}"
if [ ! -x "${TC}/clang" ]; then
  echo "clang not found at ${TC}/clang" >&2
  exit 1
fi
if [ ! -d "$SDK" ]; then
  echo "SDK not found at $SDK" >&2
  exit 1
fi
rm -rf build && mkdir -p "build/Payload/${APPNAME}.app"
APP="build/Payload/${APPNAME}.app"
"$TC/clang" -fobjc-arc -fmodules -target arm64-apple-ios14.0 -isysroot "$SDK" -O2 \
  -Wall -Wno-unused-parameter \
  src/*.m \
  -framework UIKit -framework Foundation -framework CoreGraphics \
  -o "$APP/$APPNAME"
python3 make_assets.py "$APP" "$APPNAME" "$BUNDLEID" "$DISPLAYNAME"
if command -v ldid >/dev/null 2>&1; then
  LDID="$(command -v ldid)"
elif [ -x "${TC}/ldid" ]; then
  LDID="${TC}/ldid"
else
  echo "ldid not found" >&2
  exit 1
fi
"$LDID" -S "$APP/$APPNAME"
python3 - "$APPNAME" <<'PY'
import zipfile, os, sys
name = sys.argv[1]
os.chdir("build")
ipa = "../%s.ipa" % name
with zipfile.ZipFile(ipa, "w", zipfile.ZIP_DEFLATED) as z:
    for root, dirs, files in os.walk("Payload"):
        for n in [root] + [os.path.join(root, f) for f in files]:
            info = zipfile.ZipInfo.from_file(n)
            info.compress_type = zipfile.ZIP_DEFLATED
            if os.path.isdir(n):
                z.writestr(info, b"")
            else:
                with open(n, "rb") as fh:
                    z.writestr(info, fh.read())
print("wrote", ipa)
PY
ls -la "${APPNAME}.ipa"
