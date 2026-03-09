#!/bin/bash

set -euo pipefail

REPO_URL="https://github.com/dangoquidev/smile"
THEME_NAME="smile"
GRUB_THEMES_DIR="/boot/grub/themes"
GRUB_CONFIG="/etc/default/grub"
GRUB_CFG_OUTPUT="/boot/grub/grub.cfg"
TMP_DIR="$(mktemp -d /tmp/grub-smile-install.XXXXXX)"

trap 'rm -rf "$TMP_DIR"' EXIT

[[ $EUID -eq 0 ]] || exit 1

for dep in git grub-mkconfig; do
    command -v "$dep" &>/dev/null || exit 1
done

git clone --depth=1 "$REPO_URL" "$TMP_DIR/repo" &>/dev/null || exit 1

[[ -d "$TMP_DIR/repo/$THEME_NAME" ]] || exit 1

mkdir -p "$GRUB_THEMES_DIR"
rm -rf "${GRUB_THEMES_DIR:?}/$THEME_NAME"
cp -r "$TMP_DIR/repo/$THEME_NAME" "$GRUB_THEMES_DIR/$THEME_NAME"

THEME_PATH="$GRUB_THEMES_DIR/$THEME_NAME/theme.txt"

if grep -qE '^GRUB_THEME=' "$GRUB_CONFIG" 2>/dev/null; then
    sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"$THEME_PATH\"|" "$GRUB_CONFIG"
else
    echo "GRUB_THEME=\"$THEME_PATH\"" >> "$GRUB_CONFIG"
fi

grub-mkconfig -o "$GRUB_CFG_OUTPUT" &>/dev/null || exit 1
