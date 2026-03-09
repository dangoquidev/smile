#!/bin/bash

# =============================================================================
#  setup.sh — Installe automatiquement le thème GRUB "smile"
#  Usage : wget https://raw.githubusercontent.com/dangoquidev/smile/refs/heads/main/setup.sh && sudo bash setup.sh
# =============================================================================

set -euo pipefail

# ── Couleurs ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# ── Config (hardcodé — rien à modifier) ───────────────────────────────────────
REPO_URL="https://github.com/dangoquidev/smile"
THEME_NAME="smile"
GRUB_THEMES_DIR="/boot/grub/themes"
GRUB_CONFIG="/etc/default/grub"
GRUB_CFG_OUTPUT="/boot/grub/grub.cfg"
TMP_DIR="$(mktemp -d /tmp/grub-smile-install.XXXXXX)"

# ── Helpers ───────────────────────────────────────────────────────────────────
info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[ OK ]${NC}  $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
die()     { echo -e "${RED}[ERR ]${NC}  $*" >&2; rm -rf "$TMP_DIR"; exit 1; }

trap 'rm -rf "$TMP_DIR"' EXIT

# ── Banner ────────────────────────────────────────────────────────────────────
echo -e "${BOLD}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║   Smile GRUB Theme — Auto Installer   ║"
echo "  ║   github.com/dangoquidev/smile        ║"
echo "  ╚═══════════════════════════════════════╝"
echo -e "${NC}"

# ── 1. Root ───────────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    die "Ce script doit être lancé en root.\n       Relance avec : sudo bash setup.sh"
fi

# ── 2. Dépendances ────────────────────────────────────────────────────────────
for dep in git grub-mkconfig; do
    command -v "$dep" &>/dev/null || die "'$dep' est introuvable. Installe-le puis relance."
done
success "Dépendances OK"

# ── 3. Clone du repo ──────────────────────────────────────────────────────────
info "Téléchargement du thème depuis GitHub..."
git clone --depth=1 "$REPO_URL" "$TMP_DIR/repo" &>/dev/null \
    || die "Impossible de cloner le repo. Vérifie ta connexion internet."
success "Repo téléchargé"

# ── 4. Vérification du dossier thème ─────────────────────────────────────────
[[ -d "$TMP_DIR/repo/$THEME_NAME" ]] \
    || die "Dossier '$THEME_NAME' introuvable dans le repo."
[[ -f "$TMP_DIR/repo/$THEME_NAME/theme.txt" ]] \
    || warn "Pas de theme.txt détecté — installation quand même..."
success "Dossier thème validé"

# ── 5. Installation du thème ──────────────────────────────────────────────────
mkdir -p "$GRUB_THEMES_DIR"
rm -rf "${GRUB_THEMES_DIR:?}/$THEME_NAME"
cp -r "$TMP_DIR/repo/$THEME_NAME" "$GRUB_THEMES_DIR/$THEME_NAME"
success "Thème copié → $GRUB_THEMES_DIR/$THEME_NAME"

# ── 6. Mise à jour de /etc/default/grub ──────────────────────────────────────
THEME_PATH="$GRUB_THEMES_DIR/$THEME_NAME/theme.txt"

if grep -qE '^GRUB_THEME=' "$GRUB_CONFIG" 2>/dev/null; then
    sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"$THEME_PATH\"|" "$GRUB_CONFIG"
else
    echo "GRUB_THEME=\"$THEME_PATH\"" >> "$GRUB_CONFIG"
fi
success "GRUB_THEME mis à jour dans $GRUB_CONFIG"

# ── 7. Régénération de grub.cfg ───────────────────────────────────────────────
info "Mise à jour de GRUB (peut prendre quelques secondes)..."
grub-mkconfig -o "$GRUB_CFG_OUTPUT" &>/dev/null \
    || die "grub-mkconfig a échoué. Lance-le manuellement pour voir l'erreur."
success "grub.cfg régénéré"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}  ✔ Thème Smile installé avec succès !${NC}"
echo -e "  Redémarre ta machine pour profiter du thème."
echo ""
