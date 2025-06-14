#!/bin/bash

# ─────────────────────────────────────────
# Compare two folders and generate diff report
# Usage: compare -s <source> -d <destination> -n <name> [-o <output.html>]
# ─────────────────────────────────────────

# Defaults
CUSTOM_OUTPUT=""
EXCLUDE_FILE="exclude.txt"

# Option parsing
while getopts ":s:d:n:o:" opt; do
  case $opt in
    s) SOURCE="$OPTARG" ;;
    d) TARGET="$OPTARG" ;;
    n) NAME="$OPTARG" ;;
    o) CUSTOM_OUTPUT="$OPTARG" ;;
    \?) echo "❌ Invalid option: -$OPTARG" >&2; exit 1 ;;
    :) echo "❌ Option -$OPTARG requires an argument." >&2; exit 1 ;;
  esac
done

# Validate required options
if [[ -z "$SOURCE" || -z "$TARGET" || -z "$NAME" ]]; then
  echo "❌ Missing required arguments."
  echo "Usage: $0 -s <source> -d <destination> -n <name> [-o output.html]"
  exit 1
fi

# Derived output paths


if [[ -n "$CUSTOM_OUTPUT" ]]; then
  OUTPUT_DIR="${CUSTOM_OUTPUT%/}" # remove trailing slash if present
  RSYNC_RESULT="$OUTPUT_DIR/${NAME}_RESULT_RSYNC_DRY.txt"
  TXT_OUTPUT="$OUTPUT_DIR/${NAME}_DIFFERENCES.txt"
  HTML_OUTPUT="$OUTPUT_DIR/${NAME}_DIFFERENCES.html"
  
else
  TXT_OUTPUT="${NAME}_DIFFERENCES.txt"
  HTML_OUTPUT="${NAME}_DIFFERENCES.html"
  RSYNC_RESULT="${NAME}_RESULT_RSYNC_DRY.txt"
fi

# Step 1: Build file list using rsync
rsync -avun --checksum --exclude-from="$EXCLUDE_FILE" "$SOURCE/" "$TARGET/" \
  | grep -v '/$' \
  | grep -vE '^(sending incremental file list|\.\/|^$)' \
  > "$RSYNC_RESULT"

# Step 2: Generate plain text diff
echo "Generating $TXT_OUTPUT ..."
while read -r filepath; do
  if [ ! -f "$TARGET/$filepath" ]; then
    echo "=== $filepath ==="
    echo "[MISSING IN TARGET]"
    echo
  elif [ ! -f "$SOURCE/$filepath" ]; then
    echo "=== $filepath ==="
    echo "[MISSING IN SOURCE]"
    echo
  else
    diff_output=$(diff -u "$TARGET/$filepath" "$SOURCE/$filepath" \
      | grep -E '^(@@|[-+])' | grep -vE '^(---|\+\+\+)')
    if [ -n "$diff_output" ]; then
      echo "=== $filepath ==="
      printf '%s\n' "$diff_output"
      echo
    fi
  fi
done < "$RSYNC_RESULT" > "$TXT_OUTPUT" 2>&1

# Step 3: Generate HTML report
if [ -f "$TXT_OUTPUT" ]; then
  php make_html_report.php "$TXT_OUTPUT" "$HTML_OUTPUT"
  echo "✅ HTML report generated at: $HTML_OUTPUT"
else
  echo "❌ Failed: $TXT_OUTPUT not found."
  exit 1
fi
