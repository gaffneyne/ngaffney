#!/usr/bin/env zsh
set -euo pipefail

# --- Paths (relative to eleventy/ working dir) ---
EXPORT_DIR="output/images/recent"
POSTS_DIR="recent"   # flat folder for posts
IMG_URL_PREFIX="https://ngaffney.net/images/recent"

# --- Build & deploy ---
ELEVENTY_CMD='npx @11ty/eleventy'
RSYNC_DEST='gaffneyne@ngaffney.net:/home/gaffneyne/public_html/ngaffney.net/'

# Usage:
#   ./newpost_from_export.sh "Post Title" [BASENAME]
# Example:
#   ./newpost_from_export.sh "Clouds" 08-10-25_012345
# If BASENAME is omitted, picks the newest *-1000px.jpg in EXPORT_DIR.

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 \"Post Title\" [basename]"
  exit 1
fi

TITLE="$1"
RAW_SLUG="${2:-$1}"

# Determine basename (file prefix before -1000px/-2000px)
if [[ $# -ge 2 ]]; then
  BASENAME="$2"
else
  newest1000=$(find "$EXPORT_DIR" -type f -name '*-1000px.jpg' -print0 | xargs -0 ls -t 2>/dev/null | head -n1 || true)
  if [[ -z "${newest1000}" ]]; then
    echo "No *-1000px.jpg files found in ${EXPORT_DIR}"
    exit 1
  fi
  BASENAME="$(basename "${newest1000}" | sed -E 's/-1000px\.jpg$//')"
fi

IMG_1K="${EXPORT_DIR}/${BASENAME}-1000px.jpg"
IMG_2K="${EXPORT_DIR}/${BASENAME}-2000px.jpg"

if [[ ! -f "${IMG_1K}" || ! -f "${IMG_2K}" ]]; then
  echo "Missing image pair for '${BASENAME}'. Expected:"
  echo "  ${IMG_1K}"
  echo "  ${IMG_2K}"
  exit 1
fi

# slug: lower, spaces→-, strip non-url chars
SLUG=$(echo "$RAW_SLUG" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')

# Prefer EXIF capture date; fall back to today
read_exif() {
  if command -v exiftool >/dev/null 2>&1; then
    exiftool -s -s -s -DateTimeOriginal "$1" 2>/dev/null | awk '{print $1}' | tr ':' '-'
  else
    echo ""
  fi
}
DATE_YMD="$(read_exif "${IMG_1K}")"
[[ -z "${DATE_YMD}" ]] && DATE_YMD="$(date +%Y-%m-%d)"

Y=$(echo "$DATE_YMD" | cut -d- -f1)
M=$(echo "$DATE_YMD" | cut -d- -f2)
D=$(echo "$DATE_YMD" | cut -d- -f3)
DATE_UNDERSCORE="${Y}_${M}_${D}"

# Flat filename: YYYY_MM_DD-title.md
FILE="${POSTS_DIR}/${DATE_UNDERSCORE}-${SLUG}.md"

# Front matter in your exact order, and <img> on one line (prevents Markdown <p> wrapper)
cat > "$FILE" <<EOF
---
title: ${TITLE}
date: ${Y}-${M}-${D}
layout: post.njk
---
<img srcset="${IMG_URL_PREFIX}/${BASENAME}-1000px.jpg 1x, ${IMG_URL_PREFIX}/${BASENAME}-2000px.jpg 2x" src="${IMG_URL_PREFIX}/${BASENAME}-1000px.jpg" alt="${TITLE}" />
EOF

echo "✓ Created ${FILE}"

# Build site
echo "→ Building site with Eleventy…"
${=ELEVENTY_CMD}

# Deploy via rsync (exact flags you asked for)
echo "→ Syncing output/ to ${RSYNC_DEST}"
rsync -avz --delete output/ "${RSYNC_DEST}"

echo "✓ Done."