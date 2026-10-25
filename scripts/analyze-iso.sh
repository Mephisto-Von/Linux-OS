#!/bin/bash
# Script to analyze ISO files using REA after project building
# Usage: ./scripts/analyze-iso.sh <iso-file-path>

ISO_FILE="$1"

if [ -z "$ISO_FILE" ]; then
    echo "Usage: $0 <iso-file-path>"
    exit 1
fi

if [ ! -f "$ISO_FILE" ]; then
    echo "Error: File $ISO_FILE not found"
    exit 1
fi

# Extract ISO to temporary directory
EXTRACT_DIR=$(mktemp -d)
echo "Extracting ISO to $EXTRACT_DIR"

# Try to extract using 7z or mount
if command -v 7z &>/dev/null; then
    7z x "$ISO_FILE" -o"$EXTRACT_DIR" -y 2>/dev/null || echo "7z extraction failed, trying other methods"
elif command -v mount &>/dev/null; then
    mount -o loop,ro "$ISO_FILE" /mnt/iso 2>/dev/null && echo "ISO mounted" || echo "mount failed"
fi

# Run REA analysis on extracted content
echo "Running REA analysis..."
npx rea analyze "$EXTRACT_DIR" 2>&1

# Cleanup
rm -rf "$EXTRACT_DIR"
