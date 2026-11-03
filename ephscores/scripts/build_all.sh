#!/usr/bin/env bash
# Builds EPHScores for release: the Android app (APK and/or app bundle) and
# the offline web app (PWA). Run it from anywhere; artifacts go to dist/.
#
#   scripts/build_all.sh                 # APK + web (after analyze and tests)
#   scripts/build_all.sh apk             # just the APK
#   scripts/build_all.sh all             # APK + app bundle + web
#   scripts/build_all.sh --skip-tests    # don't run flutter analyze/test first
#   scripts/build_all.sh --split apk     # one smaller APK per CPU architecture
#
# Needs Flutter on the PATH, plus the Android SDK for apk/aab (run
# `flutter doctor` to check). On Windows, use Git Bash or WSL.
set -euo pipefail

usage() {
  sed -n '2,/^set -/p' "$0" | sed '$d' | sed 's/^# \{0,1\}//'
}

targets=""
run_tests=1
split=0
for arg in "$@"; do
  case "$arg" in
    apk | aab | web) targets="$targets $arg" ;;
    all) targets="$targets apk aab web" ;;
    --skip-tests) run_tests=0 ;;
    --split) split=1 ;;
    -h | --help) usage; exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; usage >&2; exit 2 ;;
  esac
done
[ -n "$targets" ] || targets="apk web"
wants() { case " $targets " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }

cd "$(dirname "$0")/.."

command -v flutter >/dev/null 2>&1 || {
  echo "flutter was not found on the PATH. Install it from https://flutter.dev" >&2
  exit 1
}

version=$(sed -n 's/^version: *//p' pubspec.yaml | head -n 1)
echo "== EPHScores $version"
flutter --version | head -n 1

flutter pub get

if [ "$run_tests" -eq 1 ]; then
  echo "== Analyze and test"
  flutter analyze
  flutter test
fi

if { wants apk || wants aab; } && [ ! -f android/key.properties ]; then
  cat >&2 <<'EOF'

!! android/key.properties not found: the Android build will be signed with
!! the debug key. That is fine for testing on your own device, but:
!!  - it cannot update the Google Play release (different signature; you
!!    would have to uninstall the Play version first), and
!!  - Google Play rejects a debug-signed app bundle.
!! For a release, create android/key.properties (storeFile, storePassword,
!! keyAlias, keyPassword) and run again.

EOF
fi

mkdir -p dist
built=""

if wants apk; then
  echo "== Android APK"
  # Flutter doesn't clean this folder, so a split build would otherwise also
  # pick up an older universal APK (and the other way round).
  rm -f build/app/outputs/flutter-apk/app-*release.apk
  if [ "$split" -eq 1 ]; then
    flutter build apk --release --split-per-abi
  else
    flutter build apk --release
  fi
  # app-release.apk, or app-<abi>-release.apk when split.
  for apk in build/app/outputs/flutter-apk/app-*release.apk; do
    abi=$(basename "$apk" .apk)
    abi=${abi#app-}
    abi=${abi%release}
    abi=${abi%-}
    name="ephscores-$version${abi:+-$abi}.apk"
    cp "$apk" "dist/$name"
    built="$built dist/$name"
  done
fi

if wants aab; then
  echo "== Android app bundle"
  flutter build appbundle --release
  cp build/app/outputs/bundle/release/app-release.aab "dist/ephscores-$version.aab"
  built="$built dist/ephscores-$version.aab"
fi

if wants web; then
  echo "== Web app (PWA)"
  scripts/build_web.sh
fi

echo
echo "== Done"
for f in $built; do
  printf '  %-40s %s\n' "$f" "$(du -h "$f" | cut -f1)"
done
if wants web; then
  echo "  build/web                                (deploy: firebase deploy --only hosting)"
fi
