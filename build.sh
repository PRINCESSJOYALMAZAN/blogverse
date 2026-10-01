#!/usr/bin/env bash
set -euo pipefail

FLUTTER_HOME="${PWD}/.flutter"

if [ ! -x "${FLUTTER_HOME}/bin/flutter" ]; then
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "${FLUTTER_HOME}"
fi

export PATH="${FLUTTER_HOME}/bin:${PATH}"

flutter config --enable-web
flutter pub get

: "${SUPABASE_URL:?Set SUPABASE_URL in Vercel Environment Variables}"
: "${SUPABASE_PUBLISHABLE_KEY:?Set SUPABASE_PUBLISHABLE_KEY in Vercel Environment Variables}"

flutter build web --release \
  --dart-define="SUPABASE_URL=${SUPABASE_URL}" \
  --dart-define="SUPABASE_PUBLISHABLE_KEY=${SUPABASE_PUBLISHABLE_KEY}"
