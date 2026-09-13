#!/usr/bin/env bash
set -euo pipefail

export PATH="/ucrt64/bin:/usr/bin:$PATH"
export PKG_CONFIG_PATH="/ucrt64/lib/pkgconfig:/ucrt64/share/pkgconfig"

# Pin the exact FFmpeg source revision used for this release. This matches the
# 2026-09-10 Gyan git-master build revision and makes the custom build
# reproducible instead of silently changing whenever upstream master changes.
FFMPEG_COMMIT="fd7c73d01e976d2e332e85862ab63ab608710834"
BUILD_PROFILE="tinyredactiontool-v1.3.8-vfr-timeline-exact-preview"

printf '\n==> Installing the Windows build toolchain and required codec libraries\n'
pacman -Sy --needed --noconfirm \
  git make diffutils pkgconf \
  mingw-w64-ucrt-x86_64-gcc \
  mingw-w64-ucrt-x86_64-binutils \
  mingw-w64-ucrt-x86_64-nasm \
  mingw-w64-ucrt-x86_64-zlib \
  mingw-w64-ucrt-x86_64-x264 \
  mingw-w64-ucrt-x86_64-libvpx \
  mingw-w64-ucrt-x86_64-opus \
  mingw-w64-ucrt-x86_64-libwebp

SRC=/home/tinyredactiontool-ffmpeg-src
OUT=/tinyredactiontool-out
mkdir -p "$OUT"

if [[ ! -d "$SRC/.git" ]]; then
  rm -rf "$SRC"
  printf '\n==> Creating pinned FFmpeg source checkout\n'
  git init "$SRC"
  git -C "$SRC" remote add origin https://github.com/FFmpeg/FFmpeg.git
fi

cd "$SRC"
CURRENT="$(git rev-parse HEAD 2>/dev/null || true)"
if [[ "$CURRENT" != "$FFMPEG_COMMIT" ]]; then
  printf '\n==> Fetching FFmpeg commit %s\n' "$FFMPEG_COMMIT"
  # Git servers require the full, unabbreviated object ID for an exact commit
  # fetch. Verify FETCH_HEAD byte-for-byte before any source is built.
  git fetch --depth 1 origin "$FFMPEG_COMMIT"
  FETCHED="$(git rev-parse FETCH_HEAD)"
  if [[ "$FETCHED" != "$FFMPEG_COMMIT" ]]; then
    printf 'ERROR: fetched FFmpeg commit %s, expected %s\n' "$FETCHED" "$FFMPEG_COMMIT" >&2
    exit 1
  fi
  git checkout --detach "$FFMPEG_COMMIT"
  # A source revision change must never reuse an old configure result.
  rm -f ffbuild/config.mak config.h
fi

# The source commit can stay pinned while TinyRedactionTool's required FFmpeg
# feature set changes. Track that profile separately so an old configure result
# can never be silently reused after a security/functional build-profile change.
PROFILE_FILE="$SRC/.tinyredactiontool-build-profile"
CURRENT_PROFILE="$(cat "$PROFILE_FILE" 2>/dev/null || true)"
if [[ "$CURRENT_PROFILE" != "$BUILD_PROFILE" ]]; then
  printf '\n==> FFmpeg build profile changed; forcing clean reconfiguration\n'
  if [[ -f Makefile ]]; then
    make distclean >/dev/null 2>&1 || true
  fi
  rm -f ffbuild/config.mak config.h
fi

if [[ ! -f ffbuild/config.mak ]]; then
  printf '\n==> Configuring TinyRedactionTool-specific static FFmpeg + FFprobe\n'
  ./configure \
  --pkg-config-flags=--static \
  --extra-cflags='-Os -ffunction-sections -fdata-sections' \
  --extra-ldflags='-static -Wl,--gc-sections -s' \
  --enable-gpl \
  --enable-small \
  --disable-debug \
  --disable-doc \
  --disable-ffplay \
  --disable-avdevice \
  --disable-network \
  --disable-hwaccels \
  --disable-indevs \
  --disable-outdevs \
  --enable-libx264 \
  --enable-libvpx \
  --enable-libopus \
  --enable-libwebp \
  --disable-decoder=libvpx_vp8 \
  --disable-decoder=libvpx_vp9 \
  --disable-decoder=libopus \
  --disable-encoders \
  --enable-encoder=libx264 \
  --enable-encoder=libvpx_vp9 \
  --enable-encoder=aac \
  --enable-encoder=libopus \
  --enable-encoder=png \
  --enable-encoder=wrapped_avframe \
  --enable-encoder=mjpeg \
  --enable-encoder=gif \
  --enable-encoder=libwebp \
  --disable-muxers \
  --enable-muxer=mov \
  --enable-muxer=mp4 \
  --enable-muxer=ipod \
  --enable-muxer=avi \
  --enable-muxer=matroska \
  --enable-muxer=webm \
  --enable-muxer=image2 \
  --enable-muxer=image2pipe \
  --enable-muxer=null \
  --enable-muxer=gif \
  --enable-muxer=webp \
  --disable-filters \
  --enable-filter=drawbox \
  --enable-filter=crop \
  --enable-filter=boxblur \
  --enable-filter=scale \
  --enable-filter=split \
  --enable-filter=overlay \
  --enable-filter=format \
  --enable-filter=alphamerge \
  --enable-filter=palettegen \
  --enable-filter=paletteuse \
  --enable-filter=aformat \
  --enable-filter=aresample \
  --enable-filter=select
  printf '%s\n' "$BUILD_PROFILE" > "$PROFILE_FILE"
else
  printf '\n==> Reusing the existing pinned FFmpeg configuration\n'
fi

printf '\n==> Compiling ffmpeg.exe and ffprobe.exe\n'
make -j"$(nproc)" ffmpeg.exe ffprobe.exe

printf '\n==> Stripping symbols\n'
strip --strip-all ffmpeg.exe ffprobe.exe || true
cp -f ffmpeg.exe "$OUT/ffmpeg-custom.exe"
cp -f ffprobe.exe "$OUT/ffprobe-custom.exe"

printf '\n==> Custom media tools complete\n'
ls -lh "$OUT/ffmpeg-custom.exe" "$OUT/ffprobe-custom.exe"
