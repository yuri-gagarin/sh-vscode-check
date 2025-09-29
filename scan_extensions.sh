#!/bin/env bash

# This tool will scan VSCode extensions for possible compromised npm package vversions
# Will output results to console and create a CSV file in the same folder

set -u

# === DIRECTORIES CONFIG ===
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPROMISED_LIST="$SCRIPT_DIR/compromised.txt"
REPORT_FILE="$SCRIPT_DIR/vscode_scan_report.csv"

# Set EXTENSIONS_DIR for compatibility on Mac/Linux/WSL2
if [ -d "$HOME/.vscode/extensions/" ]; then
	EXTENSIONS_DIR="$HOME/.vscode/extensions"
elif [ -d "$HOME/.vscode-server/extensions" ]; then
	EXTENSIONS_DIR="$HOME/.vscode-server/extensions"
else 
	echo "ERROR: Could not resolve VSCODE extensions folder."
	exit 3
fi

if [ ! -f "$COMPROMISED_LIST" ]; then
	echo "ERROR: List of compromised packages not fount at: $COMPROMISED_LIST"
	exit 2
fi	

if [ ! -d "$EXTENSIONS_DIR" ]; then
	echo "ERROR: VSCODE extensions folder not found at: $EXTENSIONS_DIR"
	exit 3
fi

echo "Using compromised list: $COMPROMISED_LIST"
echo "Scanning extensions in: $EXTENSIONS_DIR"
echo "Report will be saved to: $REPORT_FILE"
echo "------------------------------------------------------------"

# Write CSV header
echo "extension_name,file_path,matched_line" > "$REPORT_FILE"

# Track affected extensions
declare -a AFFECTED_EXTS=()
total_checked=0

# Loop through compromised packages list
while IFS= read -r entry; do
  [ -z "$entry" ] && continue   
  echo "🔍 Checking for extension reference: $entry"
  ((total_checked++))

  for extpath in "$EXTENSIONS_DIR"/*; do
    [ -d "$extpath" ] || continue
    extname="$(basename "$extpath")"

    matches=""
    if [ -f "$extpath/package.json" ] || [ -f "$extpath/package-lock.json" ]; then
      matches=$(grep -R -n -F "$entry" \
        "$extpath/package.json" "$extpath/package-lock.json" 2>/dev/null || true)
    fi

    if [ -n "$matches" ]; then
      echo "⚠️  Extension may be affected: $extname"
      echo "$matches" | sed 's/^/    /'
      AFFECTED_EXTS+=("$extname")

      # Add each match to CSV
      while IFS= read -r line; do
        filepath=$(echo "$line" | cut -d: -f1)
        lineno=$(echo "$line" | cut -d: -f2)
        matchtext=$(echo "$line" | cut -d: -f3-)
        echo "\"$extname\",\"$filepath:$lineno\",\"$matchtext\"" >> "$REPORT_FILE"
      done <<< "$matches"

      echo "------------------------------------------------------------"
    fi
  done
done < "$COMPROMISED_LIST"

# Summary
echo
if [ "${#AFFECTED_EXTS[@]}" -eq 0 ]; then
  echo "✅ No installed VS Code extensions matched entries in compromised-packages.txt"
else
  echo "SUMMARY: ${#AFFECTED_EXTS[@]} affected extension(s):"
  for e in "${AFFECTED_EXTS[@]}"; do
    echo " - $e"
  done
  echo
  echo "Recommendation: uninstall or update the listed extensions. Example:"
  echo "  code --uninstall-extension <extension-folder-name>"
fi

echo
echo "Scanned $total_checked known compromised package(s)"
echo "CSV report saved to: $REPORT_FILE" 
