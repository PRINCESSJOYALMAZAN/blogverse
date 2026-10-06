#!/usr/bin/env bash
set -euo pipefail

# Vercel's Linux builder does not include Flutter by default.
FLUTTER_SDK_DIR="${PWD}/.flutter-sdk"

if [ ! -x "${FLUTTER_SDK_DIR}/bin/flutter" ]; then
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "${FLUTTER_SDK_DIR}"
fi

export PATH="${FLUTTER_SDK_DIR}/bin:${PATH}"
flutter config --no-analytics
flutter pub get

flutter build web --release \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-https://nfhasyisjgpaletmpvuq.supabase.co}" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="${SUPABASE_PUBLISHABLE_KEY:-sb_publishable_CvDOHCvXczV2f7zD1TpmRg_wmtyXoKJ}"
