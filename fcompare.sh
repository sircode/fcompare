#!/usr/bin/env bash

# ─────────────────────────────────────────
# Compare two folders and generate diff report (dry-run)
# Usage: fcompare.sh -s <source> -d <destination> -n <name> [-o <output.html>] [-r] [-P]
# ─────────────────────────────────────────

CUSTOM_OUTPUT=""
EXCLUDE_FILE="exclude.txt"
HELPER="fcompare_html_report.php"
HELPER_LOC="/usr/local/lib/fcompare/"
HELPER_PATH="${HELPER_LOC}${HELPER}"
RECURSIVE=false
PATCH=false

# Parse options
while getopts ":s:d:n:o:x:rP" opt; do
  case $opt in
    s) SOURCE="$OPTARG" ;;
    d) TARGET="$OPTARG" ;;
    n) NAME="$OPTARG" ;;
    o) CUSTOM_OUTPUT="$OPTARG" ;;
    x) EXCLUDE_FILE="$OPTARG" ;;
    r) RECURSIVE=true ;;
    P) PATCH=true ;;
    \?) echo "❌ Invalid option: -$OPTARG" >&2; exit 1 ;;
    :)  echo "❌ Option -$OPTARG requires an argument." >&2; exit 1 ;;
  esac
done

# Exclude-file logic
if [ -f "$EXCLUDE_FILE" ]; then
  EXCLUDE_OPTION="--exclude-from=$EXCLUDE_FILE"
else
  echo "⚠️  Exclude file '$EXCLUDE_FILE' not found; proceeding without it."
  EXCLUDE_OPTION=""
fi

# Validate required options
if [[ -z "$SOURCE" || -z "$TARGET" || -z "$NAME" ]]; then
  echo "❌ Missing required arguments."
  echo "Usage: $0 -s <source> -d <dest> -n <name> [-o <output.html>] [-r] [-P]"
  exit 1
fi

if $RECURSIVE; then
  SUFFIX="_r"
else
  SUFFIX=""
fi

# Determine output paths (uses SUFFIX)
if [[ -n "$CUSTOM_OUTPUT" ]]; then
  OUTPUT_DIR="${CUSTOM_OUTPUT%/}"
  RSYNC_RESULT="$OUTPUT_DIR/${NAME}_RESULT_RSYNC_DRY${SUFFIX}.txt"
  TXT_OUTPUT="$OUTPUT_DIR/${NAME}_DIFFERENCES${SUFFIX}.txt"
  HTML_OUTPUT="$OUTPUT_DIR/${NAME}_DIFFERENCES${SUFFIX}.html"
else
  RSYNC_RESULT="${NAME}_RESULT_RSYNC_DRY${SUFFIX}.txt"
  TXT_OUTPUT="${NAME}_DIFFERENCES${SUFFIX}.txt"
  HTML_OUTPUT="${NAME}_DIFFERENCES${SUFFIX}.html"
fi

# Step 1: Build file list
if $RECURSIVE; then
  # full recursive, rsync dry-run
  rsync -avun --checksum $EXCLUDE_OPTION "$SOURCE/" "$TARGET/" \
    | grep -v '/$' | grep -vE '^(sending incremental file list|\.\/|^$)' \
    > "$RSYNC_RESULT"
else
  # root-only dry-run: skip all directories
  rsync -avun --checksum --exclude '*/' $EXCLUDE_OPTION \
    "$SOURCE/" "$TARGET/" \
    | grep -vE '^(sending incremental file list|\.\/|^$)' \
    > "$RSYNC_RESULT"
fi

# Step 2: Generate plain-text diffs + missing markers
echo "Generating $TXT_OUTPUT ..."
{
  while read -r file; do
    if $PATCH; then
      diff -u -N "$TARGET/$file" "$SOURCE/$file"
    else
      echo "=== $file ==="
      if [ ! -f "$TARGET/$file" ]; then
        echo "[MISSING IN TARGET]"
      elif [ ! -f "$SOURCE/$file" ]; then
        echo "[MISSING IN SOURCE]"
      else
        diff -u "$TARGET/$file" "$SOURCE/$file" \
          | grep -E '^(@@|[-+])' | grep -vE '^(---|\+\+\+)'
      fi
      echo
    fi
  done
} < "$RSYNC_RESULT" > "$TXT_OUTPUT" 2>&1

# Step 3: Generate HTML report
if [ -f "$HELPER_PATH" ]; then
  FINAL_HELPER="$HELPER_PATH"
elif [ -f "./$HELPER" ]; then
  FINAL_HELPER="./$HELPER"
  echo "ℹ️  Using local $HELPER"
else
  echo "❌ '$HELPER' not found (checked $HELPER_PATH and ./)."
  exit 1
fi

if [ -f "$TXT_OUTPUT" ]; then
  php "$FINAL_HELPER" "$TXT_OUTPUT" "$HTML_OUTPUT"
  echo "✅ HTML report: $HTML_OUTPUT"
else
  echo "❌ Failed to generate $TXT_OUTPUT"
  exit 1
fi
