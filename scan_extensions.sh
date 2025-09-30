#!/bin/env bash

# Scan VSCode extensions for compromised npm packages
# Outputs to console and CSV
set -u

# === CONFIG ===
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPROMISED_LIST="$SCRIPT_DIR/compromised.txt"
REPORT_FILE="$SCRIPT_DIR/vscode_scan_report.csv"

# Resolve VSCode extensions folder
if [ -d "$HOME/.vscode/extensions/" ]; then
  EXTENSIONS_DIR="$HOME/.vscode/extensions"
elif [ -d "$HOME/.vscode-server/extensions" ]; then
  EXTENSIONS_DIR="$HOME/.vscode-server/extensions"
else 
  echo "ERROR: Could not resolve VSCode extensions folder."
  exit 1
fi

if [ ! -f "$COMPROMISED_LIST" ]; then
  echo "ERROR: Compromised list not found at $COMPROMISED_LIST"
  exit 1
fi

echo "Using compromised list: $COMPROMISED_LIST"
echo "Scanning extensions in: $EXTENSIONS_DIR"
echo "Report will be saved to: $REPORT_FILE"
echo "------------------------------------------------------------"

# CSV header
echo "extension_name,file_path,matched_line" > "$REPORT_FILE"

# List installed extensions
echo
echo "Installed VS Code extensions detected:"
mapfile -t EXT_NAMES < <(ls -1d "$EXTENSIONS_DIR"/*/ 2>/dev/null)
if [ "${#EXT_NAMES[@]}" -eq 0 ]; then
  echo "  (none found)"
else
  for ext in "${EXT_NAMES[@]}"; do
    echo "  - $(basename "$ext")"
  done
fi
echo "------------------------------------------------------------"


declare -a AFFECTED_EXTS=()
total_checked=0

# Ask user if they want detailed per-package messages
echo
read -rp "Do you want a detailed printout (y/n)? " SHOW_CHECKS
SHOW_CHECKS=$(echo "$SHOW_CHECKS" | tr '[:upper:]' '[:lower:]')  

if [ "$SHOW_CHECKS" != "y" ]; then
  echo
  echo "Working..."
  echo "------------------------------------------------------------"
fi

# --- Scan ---
while IFS= read -r entry; do
  [ -z "$entry" ] && continue

  # Split name and version at the **last** @
  pkg_name="${entry%@*}"
  pkg_version="${entry##*@}"

  if [ -z "$pkg_name" ] || [ -z "$pkg_version" ]; then
    echo "Skipping invalid entry in compromised list: $entry"
    continue
  fi

  ((total_checked++))

  # [ "$SHOW_CHECKS" = "y" ] && echo "🔍 Checking extensions for package: $entry"

  # Check each extension folder
  for extpath in "$EXTENSIONS_DIR"/*; do
    [ -d "$extpath" ] || continue
    extname="$(basename "$extpath")"

    # DEBUG LINE --- don't need at the moment
    # echo "🔍 Checking package for '$pkg_name' version '$pkg_version' in extension '$extname'"

    # Only print detailed info if SHOW_CHECKS=y
    if [ "$SHOW_CHECKS" = "y" ]; then
      echo "🔍 Checking for '$pkg_name' version '$pkg_version' in extension '$extname'"
    fi

    matches_found=0
    for file in "$extpath/package.json" "$extpath/package-lock.json"; do
      [ -f "$file" ] || continue

      while IFS= read -r line; do
        # Match lines like:
        # "fake-library": "^1.2.3"
        # "@ctrl/shared-torrent": "~6.3.0"
        if [[ $line =~ \"${pkg_name//\//\\/}\"[[:space:]]*:[[:space:]]*\"[~^@]*${pkg_version}\" ]]; then
          [ $matches_found -eq 0 ] && echo "⚠️  Extension may be affected: $extname"
          echo "    $line"
          AFFECTED_EXTS+=("$extname")
          echo "\"$extname\",\"$file\",\"$line\"" >> "$REPORT_FILE"
          matches_found=$((matches_found+1))
        fi
      done < "$file"
    done
  done
done < "$COMPROMISED_LIST"

# --- Summary ---
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
