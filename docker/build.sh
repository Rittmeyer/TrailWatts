#!/usr/bin/env bash
#
# Builds Trailwatt for one platform.
#
#   docker/build.sh web       -> build/docker/web/
#   docker/build.sh android   -> build/docker/android/app-release.apk
#   docker/build.sh ios       -> build/ios/ipa/*.ipa   (macOS only, see below)
#   docker/build.sh all       -> web + android, and iOS when run on a Mac
#
# Pass build-time configuration through DART_DEFINES, for example:
#
#   DART_DEFINES="--dart-define=TRAILWATT_STRAVA_CLIENT_ID=123" \
#     docker/build.sh web
#
# Those values end up in the image history, which is fine here and only here:
# the OAuth flows are PKCE public clients, so no client secret is ever passed
# to a build. Never add one.

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
out_root="$repo_root/build/docker"
dart_defines=${DART_DEFINES:-}

die() { printf '%s\n' "$*" >&2; exit 1; }

docker_target() {
  local target=$1 dest=$2
  command -v docker > /dev/null || die "docker is not installed."
  docker info > /dev/null 2>&1 || die "The Docker daemon is not reachable."

  printf '\n==> %s (docker)\n' "$target"
  rm -rf "$dest"
  docker build \
    --file "$repo_root/docker/Dockerfile" \
    --target "$target" \
    --build-arg "DART_DEFINES=$dart_defines" \
    --output "type=local,dest=$dest" \
    "$repo_root"
  printf '    -> %s\n' "$dest"
}

build_web() { docker_target web "$out_root/web"; }
build_android() { docker_target android "$out_root/android"; }

build_ios() {
  printf '\n==> ios (native, on this machine)\n'
  [[ $(uname -s) == Darwin ]] || die \
"iOS cannot be built here, and not because of a missing tool.

Xcode runs only on macOS, and Apple's licence does not allow macOS inside a
container on non-Apple hardware - so no Docker image exists that can compile
an iOS app. Flutter agrees: off macOS it does not even register the 'ios' and
'ipa' subcommands of 'flutter build'.

Run this script on a Mac with Xcode installed. The Xcode project is already
in ios/ and configured (bundle id app.trailwatt, trailwatt:// OAuth scheme);
what it still needs is your signing team, in Signing & Capabilities."
  command -v xcodebuild > /dev/null || die \
    "Xcode is not installed - 'xcode-select --install' only gives the CLI tools."
  command -v flutter > /dev/null || die "flutter is not on PATH."

  # shellcheck disable=SC2086  # dart_defines is several flags, not one word
  (cd "$repo_root" && flutter build ipa --release $dart_defines)
  printf '    -> %s\n' "$repo_root/build/ios/ipa"
}

case ${1:-} in
  web) build_web ;;
  android) build_android ;;
  ios) build_ios ;;
  all)
    build_web
    build_android
    if [[ $(uname -s) == Darwin ]]; then
      build_ios
    else
      printf '\n==> ios skipped: needs macOS with Xcode (docker/build.sh ios explains why)\n'
    fi
    ;;
  *)
    die "usage: docker/build.sh {web|android|ios|all}"
    ;;
esac
