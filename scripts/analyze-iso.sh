#!/usr/bin/env bash
# Analyze an ISO with REA after a build.
# Usage: ./scripts/analyze-iso.sh <iso-file-path>
set -euo pipefail

ISO_FILE="${1:-}"
EXTRACT_DIR=""
MOUNT_DIR=""
TMP_DIR=""

usage() {
    printf 'Usage: %s <iso-file-path>\n' "$0"
}

cleanup() {
    if [[ -n "$MOUNT_DIR" && -d "$MOUNT_DIR" ]] && command -v mountpoint >/dev/null 2>&1 && mountpoint -q "$MOUNT_DIR"; then
        umount "$MOUNT_DIR" 2>/dev/null || true
    fi
    if [[ -n "$TMP_DIR" ]]; then
        rm -rf "$TMP_DIR"
    fi
}
trap cleanup EXIT

if [[ -z "$ISO_FILE" ]]; then
    usage
    exit 1
fi
if [[ ! -f "$ISO_FILE" ]]; then
    printf 'Error: file not found: %s\n' "$ISO_FILE" >&2
    exit 1
fi

TMP_DIR=$(mktemp -d)
EXTRACT_DIR="$TMP_DIR/extract"
mkdir -p "$EXTRACT_DIR"

printf 'Extracting ISO to %s\n' "$EXTRACT_DIR"
if command -v 7z >/dev/null 2>&1; then
    7z x "$ISO_FILE" -o"$EXTRACT_DIR" -y >/dev/null
elif command -v xorriso >/dev/null 2>&1; then
    xorriso -osirrox on -indev "$ISO_FILE" -extract / "$EXTRACT_DIR" >/dev/null 2>&1
elif command -v mount >/dev/null 2>&1; then
    MOUNT_DIR="$TMP_DIR/mnt"
    mkdir -p "$MOUNT_DIR"
    mount -o loop,ro "$ISO_FILE" "$MOUNT_DIR"
    EXTRACT_DIR="$MOUNT_DIR"
else
    printf 'Error: install 7z, xorriso, or util-linux mount to extract the ISO\n' >&2
    exit 1
fi

if [[ -z "$(find "$EXTRACT_DIR" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
    printf 'Error: extraction produced no files\n' >&2
    exit 1
fi

if ! command -v npx >/dev/null 2>&1; then
    printf 'Error: npx is required to run REA (install Node.js)\n' >&2
    exit 1
fi

printf 'Running REA analysis...\n'
npx --yes rea analyze "$EXTRACT_DIR"
