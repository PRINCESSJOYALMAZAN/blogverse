#!/usr/bin/env bash
set -euo pipefail

FLUTTER_HOME="${PWD}/.flutter"

if [ ! -x "${FLUTTER_HOME}/bin/flutter" ]; then
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "${FLUTTER_HOME}"
fi

export PATH="${FLUTTER_HOME}/bin:${PATH}"

flutter config --enable-web
flutter pub get

SUPABASE_URL_VALUE="${SUPABASE_URL:-https://nfhasyisjgpaletmpvuq.supabase.co}"
SUPABASE_PUBLISHABLE_KEY_VALUE="${SUPABASE_PUBLISHABLE_KEY:-sb_publishable_CvDOHCvXczV2f7zD1TpmRg_wmtyXoKJ}"

flutter build web --release \
  --dart-define="SUPABASE_URL=${SUPABASE_URL_VALUE}" \
  --dart-define="SUPABASE_PUBLISHABLE_KEY=${SUPABASE_PUBLISHABLE_KEY_VALUE}"
