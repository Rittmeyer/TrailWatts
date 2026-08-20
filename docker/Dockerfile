# Trailwatt builds, one stage per platform target.
#
# Android and web are built here. iOS is not, and cannot be: Xcode runs only
# on macOS and Apple's licence does not allow macOS inside a container on
# other hardware, so no Docker image can produce an .ipa. `docker/build.sh
# ios` runs that build natively on a Mac rather than pretend otherwise.
#
# Build a target with docker/build.sh, or directly:
#   docker build -f docker/Dockerfile --target web \
#     --output type=local,dest=build/docker/web .

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
RUN useradd --create-home --shell /bin/bash builder \
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

FROM scratch AS web
COPY --from=web-build /app/build/web/ /

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
COPY --chown=builder:builder . .
RUN flutter pub get \
 && flutter build apk --release ${DART_DEFINES}

FROM scratch AS android
COPY --from=android-build /app/build/app/outputs/flutter-apk/app-release.apk /
