# syntax=docker/dockerfile:1.7
#
# Trailwatt deploy targets, one stage each. Drive it with deploy/deploy.sh;
# see deploy/README.md for what each target produces.
#
#   web         static bundle, exported to the host
#   web-server  the same bundle inside nginx - the image you actually deploy
#   android     app-release.apk / app-release.aab, exported to the host
#
# iOS is absent, and cannot be here: Xcode runs only on macOS and Apple's
# licence does not allow macOS inside a container on other hardware, so no
# Docker image can produce an .ipa. deploy/deploy.sh ios runs that build
# natively on a Mac instead of pretending otherwise.

# 3.24.5 is pinned, not merely current: newer Flutter ships a
# flutter_localizations that requires intl ^0.20, and this app pins ^0.19.
ARG FLUTTER_VERSION=3.24.5
ARG ANDROID_COMPILE_SDK=34
ARG ANDROID_BUILD_TOOLS=34.0.0
ARG ANDROID_CMDLINE_TOOLS=11076708

# --------------------------------------------------------------- flutter sdk
FROM debian:bookworm-slim AS flutter
ARG FLUTTER_VERSION
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git unzip xz-utils zip \
 && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
      | tar -xJ -C /opt
# The Flutter tool writes to its own cache, so it needs to own the SDK; it
# also refuses to be run as root without complaining at every invocation.
# The uid is pinned because the secret mounts in the android stage name it.
RUN useradd --uid 1000 --create-home --shell /bin/bash builder \
 && chown -R builder:builder /opt/flutter
USER builder
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"
RUN git config --global --add safe.directory /opt/flutter \
 && flutter config --no-analytics > /dev/null \
 && flutter --version
WORKDIR /app

# ------------------------------------------------------------------ pub deps
# Copied on its own so editing lib/ does not re-resolve every package.
FROM flutter AS deps
COPY --chown=builder:builder pubspec.yaml l10n.yaml ./
RUN flutter pub get

# ----------------------------------------------------------------------- web
FROM deps AS web-build
ARG DART_DEFINES=""
COPY --chown=builder:builder . .
# Unquoted on purpose: DART_DEFINES carries several --dart-define flags.
RUN flutter pub get \
 && flutter build web --release --web-renderer html ${DART_DEFINES}

# The bundle on its own, for a host that serves static files itself.
FROM scratch AS web
COPY --from=web-build /app/build/web/ /

# The bundle ready to run: this is what gets pushed to a registry.
#
# The unprivileged nginx image, not the stock one: it already runs as a
# non-root user and listens above 1024, which is what a platform like Cloud
# Run or a hardened Kubernetes cluster requires. Rolling that by hand on the
# stock image means chowning the cache, pid and log paths, and getting one
# of them wrong fails at runtime rather than at build.
FROM nginxinc/nginx-unprivileged:1.27-alpine AS web-server
COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=web-build /app/build/web/ /usr/share/nginx/html/
EXPOSE 8080

# ------------------------------------------------------------- android + sdk
FROM flutter AS android-sdk
USER root
ARG ANDROID_COMPILE_SDK
ARG ANDROID_BUILD_TOOLS
ARG ANDROID_CMDLINE_TOOLS
RUN apt-get update \
 && apt-get install -y --no-install-recommends openjdk-17-jdk-headless \
 && rm -rf /var/lib/apt/lists/*
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_HOME=/opt/android-sdk
RUN mkdir -p "${ANDROID_SDK_ROOT}/cmdline-tools" \
 && curl -fsSL -o /tmp/cmdline-tools.zip \
      "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}_latest.zip" \
 && unzip -q /tmp/cmdline-tools.zip -d "${ANDROID_SDK_ROOT}/cmdline-tools" \
 && mv "${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools" "${ANDROID_SDK_ROOT}/cmdline-tools/latest" \
 && rm /tmp/cmdline-tools.zip
ENV PATH="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${PATH}"
RUN yes | sdkmanager --licenses > /dev/null \
 && sdkmanager --install \
      "platform-tools" \
      "platforms;android-${ANDROID_COMPILE_SDK}" \
      "build-tools;${ANDROID_BUILD_TOOLS}" > /dev/null \
 && chown -R builder:builder "${ANDROID_SDK_ROOT}"
USER builder
RUN flutter config --android-sdk "${ANDROID_SDK_ROOT}" > /dev/null

FROM android-sdk AS android-build
ARG DART_DEFINES=""
# apk sideloads and installs; aab is what the Play Console accepts.
ARG ANDROID_FORMAT=apk
COPY --chown=builder:builder . .
# The keystore and its passwords are mounted, never copied: a secret mount
# exists only while this instruction runs, so nothing signing-related ends
# up in a layer. Without them the build falls back to the debug key, which
# installs fine and cannot be published - deploy.sh says so out loud.
RUN --mount=type=secret,id=keystore,uid=1000 \
    --mount=type=secret,id=key_properties,uid=1000 \
    set -eu; \
    if [ -f /run/secrets/key_properties ]; then \
      cp /run/secrets/key_properties android/key.properties; \
    fi; \
    flutter pub get; \
    if [ "${ANDROID_FORMAT}" = "aab" ]; then \
      flutter build appbundle --release ${DART_DEFINES}; \
    else \
      flutter build apk --release ${DART_DEFINES}; \
    fi; \
    rm -f android/key.properties; \
    mkdir -p /app/out; \
    cp build/app/outputs/flutter-apk/app-release.apk /app/out/ 2>/dev/null || true; \
    cp build/app/outputs/bundle/release/app-release.aab /app/out/ 2>/dev/null || true

FROM scratch AS android
COPY --from=android-build /app/out/ /
