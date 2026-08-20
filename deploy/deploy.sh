#!/usr/bin/env bash
#
# Builds and deploys Trailwatt for one platform.
#
#   deploy/deploy.sh web                  static bundle  -> build/deploy/web/
#   deploy/deploy.sh web --run 8080       serve it in nginx on :8080
#   deploy/deploy.sh web --push REF       push the nginx image to a registry
#   deploy/deploy.sh android              apk            -> build/deploy/android/
#   deploy/deploy.sh android --aab        app bundle for the Play Console
#   deploy/deploy.sh ios                  ipa (macOS only - see below)
#   deploy/deploy.sh all                  web + android, ios when on a Mac
#
# Build-time configuration goes in DART_DEFINES:
#
#   DART_DEFINES="--dart-define=TRAILWATT_STRAVA_CLIENT_ID=123" \
#     deploy/deploy.sh web
#
# Those values are readable in the image history, which is acceptable here
# and only here: every OAuth flow in this app is a PKCE public client, so no
# client secret is ever passed to a build. Never add one. Signing material
# is different and is handled differently - see --keystore below.

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
dockerfile="$repo_root/deploy/Dockerfile"
out_root="$repo_root/build/deploy"
dart_defines=${DART_DEFINES:-}

image_name=${TRAILWATT_IMAGE:-trailwatt-web}
image_tag=${TRAILWATT_TAG:-latest}

android_format=apk
keystore=""
key_properties=""
run_port=""
push_ref=""

die() { printf '\nerror: %s\n' "$*" >&2; exit 1; }
note() { printf '    %s\n' "$*"; }
step() { printf '\n==> %s\n' "$*"; }

require_docker() {
  command -v docker > /dev/null || die "docker is not installed."
  docker info > /dev/null 2>&1 ||
    die "the Docker daemon is not reachable - is it running?"
}

usage() {
  # The header comment above is the help text; print it until it ends.
  awk 'NR > 2 && /^#/ { sub(/^# ?/, ""); print; next } NR > 2 { exit }' \
    "${BASH_SOURCE[0]}"
  exit "${1:-1}"
}

# ---------------------------------------------------------------------- web
build_web() {
  require_docker
  local dest="$out_root/web"

  step "web bundle"
  rm -rf "$dest"
  docker build \
    --file "$dockerfile" \
    --target web \
    --build-arg "DART_DEFINES=$dart_defines" \
    --output "type=local,dest=$dest" \
    "$repo_root"
  note "$dest"

  # The runnable image is built whenever it might be used, and always when
  # the bundle is: a static export nobody can serve is half a deploy.
  step "web image ($image_name:$image_tag)"
  docker build \
    --file "$dockerfile" \
    --target web-server \
    --build-arg "DART_DEFINES=$dart_defines" \
    --tag "$image_name:$image_tag" \
    "$repo_root"
  note "docker run --rm -p 8080:8080 $image_name:$image_tag"

  if [[ -n $push_ref ]]; then
    step "push $push_ref"
    docker tag "$image_name:$image_tag" "$push_ref"
    docker push "$push_ref"
  fi

  if [[ -n $run_port ]]; then
    step "serving on http://localhost:$run_port (ctrl-c to stop)"
    docker run --rm -p "$run_port:8080" "$image_name:$image_tag"
  fi
}

# ------------------------------------------------------------------ android
build_android() {
  local dest="$out_root/android"
  local -a secrets=()

  # Checked before the daemon and before any layer is built: a typo in a
  # keystore path should fail now, not twenty minutes into a build.
  if [[ -n $keystore ]]; then
    [[ -f $keystore ]] || die "keystore not found: $keystore"
    [[ -n $key_properties ]] ||
      die "--keystore needs --key-properties (storeFile, storePassword, keyAlias, keyPassword)."
    [[ -f $key_properties ]] || die "key.properties not found: $key_properties"
    grep -q '^storeFile=/run/secrets/keystore$' "$key_properties" ||
      die "$key_properties must set storeFile=/run/secrets/keystore - that is where the keystore is mounted during the build."
    secrets+=(--secret "id=keystore,src=$keystore")
    secrets+=(--secret "id=key_properties,src=$key_properties")
  fi

  require_docker

  step "android $android_format"
  rm -rf "$dest"
  DOCKER_BUILDKIT=1 docker build \
    --file "$dockerfile" \
    --target android \
    --build-arg "DART_DEFINES=$dart_defines" \
    --build-arg "ANDROID_FORMAT=$android_format" \
    "${secrets[@]}" \
    --output "type=local,dest=$dest" \
    "$repo_root"
  note "$dest"

  if [[ -z $keystore ]]; then
    cat >&2 <<'WARN'

    Signed with the debug key, because no --keystore was given. That
    installs for testing and the Play Console rejects it. To sign for
    real, pass --keystore and --key-properties.
WARN
  fi
}

# ---------------------------------------------------------------------- ios
build_ios() {
  [[ $(uname -s) == Darwin ]] || die \
"iOS cannot be built here, and not for want of a tool to install.

Xcode runs only on macOS, and Apple's licence does not allow macOS inside a
container on non-Apple hardware - so there is no Docker image, anywhere, that
compiles an iOS app. Flutter agrees: off macOS it does not even register the
'ios' and 'ipa' subcommands of 'flutter build'.

Run this script on a Mac with Xcode. The Xcode project is committed and
configured already (bundle id app.trailwatt, the trailwatt:// OAuth scheme);
what it still needs is your signing team, in Signing & Capabilities."

  command -v xcodebuild > /dev/null ||
    die "Xcode is not installed - 'xcode-select --install' gives only the CLI tools."
  command -v flutter > /dev/null || die "flutter is not on PATH."

  step "ios ipa (native - Docker is not involved)"
  # shellcheck disable=SC2086  # several flags, not one word
  (cd "$repo_root" && flutter build ipa --release $dart_defines)
  note "$repo_root/build/ios/ipa"
}

# -------------------------------------------------------------------- entry
target=${1:-}
[[ -n $target ]] || usage 1
shift || true

while [[ $# -gt 0 ]]; do
  case $1 in
    --aab) android_format=aab ;;
    --apk) android_format=apk ;;
    --keystore) keystore=${2:?--keystore needs a path}; shift ;;
    --key-properties) key_properties=${2:?--key-properties needs a path}; shift ;;
    --run)
      # The port is optional: "--run" alone means 8080.
      if [[ ${2:-} =~ ^[0-9]+$ ]]; then run_port=$2; shift; else run_port=8080; fi
      ;;
    --push) push_ref=${2:?--push needs an image reference}; shift ;;
    -h|--help) usage 0 ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

case $target in
  web) build_web ;;
  android) build_android ;;
  ios) build_ios ;;
  all)
    build_web
    build_android
    if [[ $(uname -s) == Darwin ]]; then
      build_ios
    else
      printf '\n==> ios skipped: needs macOS with Xcode ("deploy/deploy.sh ios" explains why)\n'
    fi
    ;;
  -h|--help) usage 0 ;;
  *) die "unknown target: $target (want web, android, ios or all)" ;;
esac
