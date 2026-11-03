#!/bin/sh
# Builds the offline-capable PWA into build/web.
set -e
cd "$(dirname "$0")/.."
# Bundle the renderer instead of loading it from Google's CDN (offline use).
flutter build web --release --no-web-resources-cdn "$@"
# Flutter's own service worker is a deprecated stub; ours is sw.js.
rm -f build/web/flutter_service_worker.js
dart run scripts/gen_sw.dart build/web
