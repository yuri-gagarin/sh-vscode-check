# VS Code Extension Security Scanner

This script scans your installed VS Code extensions for known compromised npm packages from the Shai-Hulud attack It will print a report to the console and will output a CSV file for further inspection.

---

## Prerequisites

- Bash shell (Linux, macOS, or WSL2)
- VS Code installed
- `compromised.txt` containing the known compromised package names (one per line)
- The script (`scan_extensions.sh`) and `compromised.txt` file cloned/copied into the same folder

---

## Installation / Setup

Clone or copy the repo to your home directory or a folder of your choice:

```bash
git clone https://github.com/yuri-gagarin/sh-vscode-check.git ~/sh_scan
cd ~/sh_scan
# make it executable
chmod +x scan_extensions.sh
# run the program
./scan_extensions.sh
```

## Example Output
Installed VS Code extensions detected:
  - my-vscode-theme-1.0.0
  - python-2025.1.0
------------------------------------------------------------
🔍 Checking for extension reference: @ctrl/tinycolor@4.1.1
⚠️  Extension may be affected: my-vscode-theme-1.0.0
    /home/user/.vscode/extensions/my-vscode-theme-1.0.0/package.json:12: "@ctrl/tinycolor": "4.1.1"
------------------------------------------------------------

SUMMARY: 1 affected extension(s):
 - my-vscode-theme-1.0.0 

CSV report saved to: /home/user/sh_scan/vscode-scan-report.csv


## What to Do if an Extension Is Found to Be Compromised
If the scan identifies any affected extensions:

**Do not panic** — the script only detects potential risk.
**Uninstall the affected extension(s)** using a terminal command or VS Code

- Either:

```bash
code --uninstall-extension <extension-folder-name>
```

- Or:
Using the VS Code GUI

1. Open VS Code.

2. Click on the Extensions icon on the sidebar (or press Ctrl+Shift+X / Cmd+Shift+X on Mac).

3. Search for the extension by name.

4. Click the Uninstall button.

5. Restart VS Code to complete the process.