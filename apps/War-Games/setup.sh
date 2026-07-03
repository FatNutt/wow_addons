#!/usr/bin/env bash
# ============================================================================
# Better Addons WoW Template — Setup Script
# ============================================================================
# Creates a new WoW addon from the Midnight Addon Template.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/FRIKKern/Better-Addons-WoW-Template/main/setup.sh | bash -s -- "AddonName" "AuthorName"
#
# Or clone first:
#   git clone https://github.com/FRIKKern/Better-Addons-WoW-Template.git MyAddon
#   cd MyAddon && bash setup.sh "MyAddon" "AuthorName"
# ============================================================================

set -euo pipefail

# ---- Parse Arguments ----
ADDON_NAME="${1:-}"
AUTHOR_NAME="${2:-}"

if [[ -z "$ADDON_NAME" ]]; then
    echo "Usage: setup.sh <AddonName> [AuthorName]"
    echo ""
    echo "  AddonName   PascalCase addon name (e.g. CoolFrames, RaidHelper)"
    echo "  AuthorName  Your name for the TOC and LICENSE (default: YourName)"
    exit 1
fi

AUTHOR_NAME="${AUTHOR_NAME:-YourName}"

# ---- Validate Addon Name ----
# WoW addon folder names: letters, numbers, underscores, hyphens. No spaces.
if [[ ! "$ADDON_NAME" =~ ^[A-Za-z][A-Za-z0-9_-]*$ ]]; then
    echo "Error: Addon name must start with a letter and contain only letters, numbers, underscores, or hyphens."
    exit 1
fi

# ---- Derive Variants ----
# MYADDON → UPPERCASE for SLASH_ and SlashCmdList
ADDON_UPPER=$(echo "$ADDON_NAME" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
# myaddon → lowercase for slash commands
ADDON_LOWER=$(echo "$ADDON_NAME" | tr '[:upper:]' '[:lower:]' | tr '-' '_')
# Short alias: first letters of each PascalCase word, or first 2 chars
ADDON_SHORT=$(echo "$ADDON_NAME" | sed 's/\([A-Z]\)/\n\1/g' | sed '/^$/d' | cut -c1 | tr '[:upper:]' '[:lower:]' | tr -d '\n')
if [[ ${#ADDON_SHORT} -lt 2 ]]; then
    ADDON_SHORT="${ADDON_LOWER:0:2}"
fi

echo "Setting up: $ADDON_NAME"
echo "  Author:    $AUTHOR_NAME"
echo "  Slash:     /$ADDON_LOWER (alias: /$ADDON_SHORT)"
echo "  Globals:   ${ADDON_NAME}DB, SLASH_${ADDON_UPPER}1"
echo ""

# ---- Clone if running via curl (not already in repo) ----
if [[ ! -f "MyAddon.toc" ]]; then
    echo "Cloning template..."
    git clone --depth=1 https://github.com/FRIKKern/Better-Addons-WoW-Template.git "$ADDON_NAME"
    cd "$ADDON_NAME"
fi

# ---- Rename TOC File ----
if [[ -f "MyAddon.toc" ]]; then
    mv "MyAddon.toc" "${ADDON_NAME}.toc"
    echo "Renamed MyAddon.toc → ${ADDON_NAME}.toc"
fi

# ---- Replace in All Text Files ----
# Order matters: longer/more-specific patterns first to avoid partial matches.

# Files to process (only files that contain template placeholders)
FILES=(
    "${ADDON_NAME}.toc"
    "Init.lua"
    "Core.lua"
    ".luacheckrc"
    ".pkgmeta"
    "CLAUDE.md"
    ".cursorrules"
    "CHANGELOG.md"
    "LICENSE"
    "README.md"
)

# Only process files that exist
EXISTING_FILES=()
for f in "${FILES[@]}"; do
    [[ -f "$f" ]] && EXISTING_FILES+=("$f")
done

if [[ ${#EXISTING_FILES[@]} -eq 0 ]]; then
    echo "Error: No template files found. Are you in the right directory?"
    exit 1
fi

# Detect sed flavor (macOS vs GNU)
if sed --version >/dev/null 2>&1; then
    SED_CMD="sed -i"
else
    SED_CMD="sed -i ''"
fi

do_sed() {
    local pattern="$1"
    shift
    if sed --version >/dev/null 2>&1; then
        sed -i "$pattern" "$@"
    else
        sed -i '' "$pattern" "$@"
    fi
}

echo "Renaming identifiers..."

# 1. Compartment callbacks: MyAddon_On → AddonName_On
do_sed "s/MyAddon_On/${ADDON_NAME}_On/g" "${EXISTING_FILES[@]}"

# 2. SavedVariables: MyAddonDB → AddonNameDB, MyAddonCharDB → AddonNameCharDB
do_sed "s/MyAddonDB/${ADDON_NAME}DB/g" "${EXISTING_FILES[@]}"
do_sed "s/MyAddonCharDB/${ADDON_NAME}CharDB/g" "${EXISTING_FILES[@]}"

# 3. Frame names: MyAddonInfoFrame → AddonNameInfoFrame
do_sed "s/MyAddonInfoFrame/${ADDON_NAME}InfoFrame/g" "${EXISTING_FILES[@]}"

# 4. SLASH globals: SLASH_MYADDON → SLASH_ADDONUPPER, SlashCmdList["MYADDON"]
do_sed "s/SLASH_MYADDON/SLASH_${ADDON_UPPER}/g" "${EXISTING_FILES[@]}"
do_sed "s/SlashCmdList\[\"MYADDON\"\]/SlashCmdList[\"${ADDON_UPPER}\"]/g" "${EXISTING_FILES[@]}"

# 5. Slash command strings: /myaddon → /addonlower
do_sed "s|/myaddon|/${ADDON_LOWER}|g" "${EXISTING_FILES[@]}"

# 6. Short alias: the template hardcodes /ma as the short alias.
#    Replace it BEFORE the general MyAddon rename.
do_sed "s|= \"/ma\"  -- Short alias|= \"/${ADDON_SHORT}\"  -- Short alias|" Init.lua

# 7. Remaining MyAddon → AddonName (package-as, titles, generic references)
do_sed "s/MyAddon/${ADDON_NAME}/g" "${EXISTING_FILES[@]}"

# 8. Author name
do_sed "s/YourName/${AUTHOR_NAME}/g" "${EXISTING_FILES[@]}"

echo "Renamed all identifiers."

# ---- Reset Git History ----
echo "Resetting git history..."
rm -rf .git
git init -q
git add -A
git commit -q -m "Initial commit from Better Addons WoW Template (Midnight 12.0+)"

# ---- Remove This Script ----
rm -f setup.sh
git add -A
git commit -q -m "Remove setup script"

echo ""
echo "Done! Your addon '$ADDON_NAME' is ready."
echo ""
echo "Next steps:"
echo "  1. cd ${ADDON_NAME} (if you used curl)"
echo "  2. Link to WoW: ln -s \"\$(pwd)\" \"/path/to/WoW/_retail_/Interface/AddOns/${ADDON_NAME}\""
echo "  3. Code your addon — edit Init.lua, Core.lua, Config.lua"
echo "  4. Test: /reload in-game"
echo "  5. Ship: git tag v1.0.0 && git push origin v1.0.0"
echo ""
echo "  Set up CI/CD secrets for auto-upload:"
echo "    CF_API_KEY, WAGO_API_TOKEN, WOWI_API_TOKEN"
echo "    (Settings > Secrets > Actions in your GitHub repo)"
