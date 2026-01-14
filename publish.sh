#!/usr/bin/env bash
set -euo pipefail

# --- config you can tweak ---
OUTDIR="${OUTDIR:-output}"   # your 11ty output folder (you've been using "output/")
BUILD_CMD="${BUILD_CMD:-npx @11ty/eleventy}"
REMOTE="${REMOTE:-ng:/home/gaffneyne/public_html/ngaffney.net/}"  # uses your ssh config alias "ng"
EXCLUDES=(
  ".DS_Store"
  "node_modules/"
  ".git/"
  ".env"
)
# ----------------------------

DRYRUN=false
SKIP_BUILD=false

for arg in "$@"; do
  case "$arg" in
    -n|--dry-run) DRYRUN=true ;;
    --skip-build) SKIP_BUILD=true ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

log() { printf "\n==> %s\n" "$*"; }

# quick connectivity check (won't prompt thanks to your SSH key)
log "Checking SSH connectivity to $REMOTE"
if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "${REMOTE%%:*}" 'echo ok' >/dev/null 2>&1; then
  echo "Could not connect via SSH key to ${REMOTE%%:*}. Make sure your key works:  ssh ${REMOTE%%:*}" >&2
  exit 1
fi

if [ "$SKIP_BUILD" = false ]; then
  log "Building site with: $BUILD_CMD"
  $BUILD_CMD
else
  log "Skipping build (--skip-build)"
fi

if [ ! -d "$OUTDIR" ]; then
  echo "Output dir '$OUTDIR' not found. Set OUTDIR or run the build." >&2
  exit 1
fi

# build rsync exclude args
RSYNC_EXCLUDES=()
for p in "${EXCLUDES[@]}"; do
  RSYNC_EXCLUDES+=(--exclude "$p")
done

log "Syncing '$OUTDIR/' to '$REMOTE'"
set -x
rsync -azvh --delete \
  "${RSYNC_EXCLUDES[@]}" \
  "$([ "$DRYRUN" = true ] && echo --dry-run)" \
  "${OUTDIR%/}/" "$REMOTE"
set +x

log "Done!"