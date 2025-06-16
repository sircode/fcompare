#!/bin/bash

# ─────────────────────────────────────────
# Compare two folders and generate diff report
# Usage: compare -s <source> -d <destination> -n <name> [-o <output.html>]
# ─────────────────────────────────────────

# Defaults
CUSTOM_OUTPUT=""
EXCLUDE_FILE="exclude.txt"
HELPER="fcompare_html_report.php"
HELPER_LOC="/usr/local/lib/fcompare/"
HELPER_PATH="${HELPER_LOC}${HELPER}"

# Option parsing
while getopts ":s:d:n:o:x:" opt; do
  case $opt in
    s) SOURCE="$OPTARG" ;;
    d) TARGET="$OPTARG" ;;
    n) NAME="$OPTARG" ;;
    o) CUSTOM_OUTPUT="$OPTARG" ;;
    x) EXCLUDE_FILE="$OPTARG" ;;
    \?) echo "❌ Invalid option: -$OPTARG" >&2; exit 1 ;;
    :)  echo "❌ Option -$OPTARG requires an argument." >&2; exit 1 ;;
  esac
done



# Later in the script, before rsync:
if [ ! -f "$EXCLUDE_FILE" ]; then
  echo "⚠️  Warning: Exclude file '$EXCLUDE_FILE' not found. Continuing without it."
  EXCLUDE_OPTION=""
else
  EXCLUDE_OPTION="--exclude-from=$EXCLUDE_FILE"
fi


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
rsync -avun --checksum $EXCLUDE_OPTION "$SOURCE/" "$TARGET/" \
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

# Try system-wide first, then fallback to local
if [ -f "$HELPER_PATH" ]; then
  FINAL_HELPER="$HELPER_PATH"
elif [ -f "./$HELPER" ]; then
  FINAL_HELPER="./$HELPER"
  echo "ℹ️  Using local $HELPER"
else
  echo "❌ HTML report generator '$HELPER' not found."
  echo "   Expected at: $HELPER_PATH"
  echo "   Or:          ./$HELPER"
  exit 1
fi

# Step 3: Generate HTML report
if [ -f "$TXT_OUTPUT" ]; then
  php "$FINAL_HELPER" "$TXT_OUTPUT" "$HTML_OUTPUT"
  echo "✅ HTML report generated at: $HTML_OUTPUT"
else
  echo "❌ Failed: $TXT_OUTPUT not found."
  exit 1
fi
