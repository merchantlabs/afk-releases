#!/usr/bin/env sh
# Installs the afk CLI from a merchantlabs/afk-releases GitHub Release into
# ~/.local/bin. Published verbatim as install.sh on that repo's GitHub Pages
# site by scripts/release.sh -- edit this file, not the copy on Pages.
#
#   curl -fsSL https://merchantlabs.github.io/afk-releases/install.sh | sh
#
# POSIX sh, not bash: this has to run under whatever /bin/sh a `curl | sh`
# finds, which is dash on plenty of Linux boxes.

set -eu

BASE_URL="${AFK_INSTALL_BASE:-https://merchantlabs.github.io/afk-releases}"
DEST_DIR="${AFK_INSTALL_DIR:-$HOME/.local/bin}"

uname_s="$(uname -s)"
case "$uname_s" in
  Darwin) OS=darwin ;;
  Linux) OS=linux ;;
  *) echo "install.sh: unsupported OS $uname_s" >&2; exit 1 ;;
esac

uname_m="$(uname -m)"
case "$uname_m" in
  arm64|aarch64) ARCH=arm64 ;;
  x86_64|amd64) ARCH=amd64 ;;
  *) echo "install.sh: unsupported architecture $uname_m" >&2; exit 1 ;;
esac

KEY="$OS-$ARCH"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "afk: fetching $BASE_URL/latest.json"
curl -fsSL "$BASE_URL/latest.json" -o "$WORK/latest.json"

# latest.json is small and flat (afk always writes it, in scripts/release.sh),
# so grep/sed read it without needing jq -- not every machine curl runs on has
# jq installed. But release.sh pretty-prints it, so a key and its "url" can
# land on separate lines; flatten to one line first. Safe because neither a
# URL nor a hex digest ever contains whitespace.
FLAT="$(tr -d ' \n\t' < "$WORK/latest.json")"

VERSION="$(printf '%s' "$FLAT" | sed -n 's/.*"version":"\([^"]*\)".*/\1/p')"
[ -n "$VERSION" ] || { echo "install.sh: could not read a version from latest.json" >&2; exit 1; }

URL="$(printf '%s' "$FLAT" | sed -n "s/.*\"$KEY\":{\"url\":\"\\([^\"]*\\)\".*/\\1/p")"
[ -n "$URL" ] || { echo "install.sh: latest.json has no release asset for $KEY" >&2; exit 1; }
FILE="$(basename "$URL")"
RELEASE_URL="$(dirname "$URL")"

echo "afk: downloading $URL"
curl -fsSL "$URL" -o "$WORK/$FILE"
curl -fsSL "$RELEASE_URL/SHA256SUMS" -o "$WORK/SHA256SUMS"

echo "afk: verifying checksum against SHA256SUMS"
EXPECTED="$(grep " $FILE\$" "$WORK/SHA256SUMS" | cut -d' ' -f1)"
[ -n "$EXPECTED" ] || { echo "install.sh: $FILE is not listed in SHA256SUMS" >&2; exit 1; }
if command -v sha256sum >/dev/null 2>&1; then
  ACTUAL="$(sha256sum "$WORK/$FILE" | cut -d' ' -f1)"
else
  ACTUAL="$(shasum -a 256 "$WORK/$FILE" | cut -d' ' -f1)"
fi
if [ "$ACTUAL" != "$EXPECTED" ]; then
  echo "install.sh: checksum mismatch for $FILE" >&2
  echo "  expected $EXPECTED" >&2
  echo "  got      $ACTUAL" >&2
  echo "Refusing to install." >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
case "$FILE" in
  *.gz) gunzip -c "$WORK/$FILE" > "$WORK/afk-bin" ;;
  *) cp "$WORK/$FILE" "$WORK/afk-bin" ;;
esac
chmod +x "$WORK/afk-bin"
mv "$WORK/afk-bin" "$DEST_DIR/afk"

echo "afk $VERSION installed to $DEST_DIR/afk"
case ":$PATH:" in
  *":$DEST_DIR:"*) ;;
  *) echo "$DEST_DIR is not on your PATH. Add it to your shell profile: export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac
