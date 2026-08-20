# Deploy

One entry point for all three platforms:

```bash
deploy/deploy.sh web        # static bundle + a runnable nginx image
deploy/deploy.sh android    # apk, or --aab for the Play Console
deploy/deploy.sh ios        # ipa - macOS only, see below
deploy/deploy.sh all
```

Artifacts land in `build/deploy/<platform>/`. `deploy/deploy.sh --help`
prints the full set of options.

## What Docker does and does not cover

| Platform | Built in Docker | Output |
|---|---|---|
| web | yes | `build/deploy/web/` and the image `trailwatt-web:latest` |
| android | yes | `app-release.apk`, or `app-release.aab` with `--aab` |
| ios | **no** | `build/ios/ipa/*.ipa`, built natively on macOS |

iOS is not a gap to fill later. Xcode runs only on macOS, and Apple's
licence does not allow macOS inside a container on non-Apple hardware, so no
Docker image anywhere compiles an iOS app. Flutter agrees: off macOS it does
not register the `ios` and `ipa` subcommands at all. `deploy/deploy.sh ios`
runs the native build on a Mac and refuses, with that explanation, anywhere
else. The Xcode project in `ios/` is committed and configured — bundle id
`app.trailwatt`, the `trailwatt://` OAuth scheme — and needs your signing
team filled in under *Signing & Capabilities*.

## Web

`deploy/deploy.sh web` produces both the static bundle and
`trailwatt-web:latest`, because a bundle nobody can serve is half a deploy.

```bash
deploy/deploy.sh web --run 8080          # serve it locally
deploy/deploy.sh web --push registry.example.com/trailwatt:2026-08-20
```

The nginx config (`deploy/nginx.conf`) is mostly about what must *not* be
cached. `index.html`, `flutter_service_worker.js` and `version.json` are the
only files that know which build is current, so caching any of them pins a
browser to an old release — the classic "I deployed and users still see the
old app". Everything else is content-addressed and cached hard.

The image is `nginxinc/nginx-unprivileged`, running as a non-root user on
port 8080, which is what Cloud Run and most hardened clusters require.

## Android

Without a keystore the release is signed with the debug key: it installs for
testing, and the Play Console rejects it. The script says so after every
unsigned build.

To sign for real, write a `key.properties` whose `storeFile` points at where
the build mounts the keystore:

```properties
storeFile=/run/secrets/keystore
storePassword=...
keyAlias=trailwatt
keyPassword=...
```

```bash
deploy/deploy.sh android --aab \
  --keystore ~/keys/trailwatt.jks \
  --key-properties ~/keys/key.properties
```

Both are BuildKit secrets, mounted only while that one instruction runs, so
neither the keystore nor the passwords end up in an image layer. Keep both
files out of the repo — `android/.gitignore` already covers `key.properties`
and `*.jks`.

## Build-time configuration

Client ids and server URLs go in `DART_DEFINES`:

```bash
DART_DEFINES="--dart-define=TRAILWATT_STRAVA_CLIENT_ID=123 \
--dart-define=TRAILWATT_OSRM_URL=https://osrm.suainfra" \
  deploy/deploy.sh web
```

These are readable in the image history. That is acceptable here **and only
here**: every OAuth flow in this app is a PKCE public client, so no client
secret is ever passed to a build. Never add one — see the integrations
section of the root README.
