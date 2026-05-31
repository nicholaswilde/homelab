#!/usr/bin/env bash
################################################################################
#
# Script Name: sync.sh
# ----------------
# Checks all projects for updates and builds/uploads them if needed.
#
# @author Nicholas Wilde, 0xb299a622
# @date 09 May 2026
# @version 1.0.0
#
################################################################################

# Options
set -e
set -o pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BUILDERS_DIR=$(dirname "$SCRIPT_DIR")
PARENT_DIR=$(dirname "$BUILDERS_DIR")

# Load Configuration
ENV_FILE="${PARENT_DIR}/.env"
if [[ -f "$ENV_FILE" ]]; then
  source "$ENV_FILE"
fi

cd "$BUILDERS_DIR"

# Projects list format: "alias:package:repo"
PROJECTS=(
  "restic:restic:restic/restic"
  "sops:sops:getsops/sops"
  "bat:bat:sharkdp/bat"
  "fd:fd:sharkdp/fd"
  "eget:eget:zyedidia/eget"
  "ubi:ubi:houseabsolute/ubi"
  "fresh:fresh:sinelaw/fresh"
  "yazi:yazi:sxyazi/yazi"
  "system-bridge:system-bridge:timmo001/system-bridge"
  "procs:procs:dalance/procs"
  "lnav:lnav:tstack/lnav"
  "neovim:neovim:neovim/neovim"
  "pvetui:pvetui:devnullvoid/pvetui"
  "lastpass-cli:lpass:lastpass/lastpass-cli"
)

for entry in "${PROJECTS[@]}"; do
  IFS=':' read -r alias pkg repo <<< "$entry"
  
  # 1. Check for new version
  # We use '|| true' or a temporary variable to prevent 'set -e' from exiting
  if NEW_TAG=$(./scripts/check_version.sh "$pkg" "$repo" 2>/dev/null); then
    echo "🚀 Updating $alias to $NEW_TAG..."
    
    # 2. Build the app
    if ! VERSION="$NEW_TAG" task "$alias:build"; then
        echo "❌ Failed to build $alias"
        continue
    fi
    
    # 3. Upload the app
    if ! ./upload.sh; then
        echo "❌ Failed to upload $alias"
        continue
    fi
    
    # 4. (Optional) Selective cleanup
    # We no longer run 'task clean-all' here to preserve compiler caches.
    # task restic:clean # if you add per-project cleanup
  else
    echo "✅ $alias is up to date."
  fi
done
