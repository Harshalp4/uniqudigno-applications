#!/usr/bin/env bash
# Obfuscated release builds (Section 4D — code obfuscation + split debug info).
# Debug symbols are written separately and must never ship in the app bundle.
set -euo pipefail

DEBUG_INFO_DIR="./build/debug-info"
# Production config is injected via --dart-define (never hardcoded):
#   API_BASE_URL  — https://api.vitalscan.app/api/v1
#   CERT_PINS     — comma-separated base64 SHA-256 leaf + backup-CA fingerprints
API_BASE_URL="${API_BASE_URL:-https://api.vitalscan.app/api/v1}"
CERT_PINS="${CERT_PINS:-}"

DEFINES=(--dart-define=API_BASE_URL="$API_BASE_URL")
[ -n "$CERT_PINS" ] && DEFINES+=(--dart-define=CERT_PINS="$CERT_PINS")

echo "▶ Android (obfuscated)…"
flutter build apk --release --obfuscate \
  --split-debug-info="$DEBUG_INFO_DIR/android" "${DEFINES[@]}"

echo "▶ iOS (obfuscated)…"
flutter build ios --release --obfuscate \
  --split-debug-info="$DEBUG_INFO_DIR/ios" "${DEFINES[@]}"

echo "✔ Builds complete. Debug symbols in $DEBUG_INFO_DIR (store separately, do not distribute)."
