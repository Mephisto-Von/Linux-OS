#!/usr/bin/env bash
# Fast, dependency-light smoke tests for the Samurai scripts.
set -euo pipefail

REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

pass=0
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
ok() { pass=$((pass + 1)); printf 'ok %d - %s\n' "$pass" "$*"; }

assert_contains() {
    local haystack="$1" needle="$2" label="$3"
    [[ "$haystack" == *"$needle"* ]] || fail "$label: expected '$needle' in '$haystack'"
}

assert_file() {
    [[ -f "$1" ]] || fail "expected file: $1"
}

# Shell files: every file in samurai/scripts, plus named shell files elsewhere.
find_shell_files() {
    find "$REPO_ROOT/samurai/scripts" -type f
    find "$REPO_ROOT/scripts" "$REPO_ROOT/build" "$REPO_ROOT/tests" -type f \
        \( -name '*.sh' -o -name 'config' -o -name '*.hook.chroot' \)
}

# 1. Syntax checks
while IFS= read -r file; do
    bash -n "$file" || fail "syntax error: $file"
done < <(find_shell_files)
ok "all shell scripts parse"

# 2. ShellCheck when available
if command -v shellcheck >/dev/null 2>&1; then
    while IFS= read -r file; do
        shellcheck -x "$file" || fail "shellcheck: $file"
    done < <(find_shell_files)
    ok "shellcheck passed"
else
    printf 'skip - shellcheck not installed\n'
fi

# 3. Python syntax
if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import ast, pathlib, sys; ast.parse(pathlib.Path(sys.argv[1]).read_text())' \
        "$REPO_ROOT/scripts/use-heretic.py"
    ok "python script parses"
fi

# 4. AI CLI usage, default model, and file credentials
HOME_DIR="$TMP/home"
mkdir -p "$HOME_DIR"
export SAMURAI_AI_FORCE_FILE=1

out=$(HOME="$HOME_DIR" bash "$REPO_ROOT/samurai/scripts/samurai-ai")
assert_contains "$out" "Samurai AI Assistant" "ai usage"

HOME="$HOME_DIR" bash "$REPO_ROOT/samurai/scripts/samurai-ai" set-default "llama3.2:3b" >/dev/null
assert_file "$HOME_DIR/.config/samurai/ai-default"
[[ "$(HOME="$HOME_DIR" bash "$REPO_ROOT/samurai/scripts/samurai-ai" get-default)" == "llama3.2:3b" ]] \
    || fail "get-default returned the wrong value"
ok "default model persists"

mkdir -p "$TMP/bin"
cat > "$TMP/bin/ollama" <<'EOF'
#!/bin/sh
printf 'ollama-args:%s\n' "$*"
EOF
chmod 0755 "$TMP/bin/ollama"
out=$(PATH="$TMP/bin:$PATH" HOME="$HOME_DIR" bash "$REPO_ROOT/samurai/scripts/samurai-ai" chat hello)
[[ "$out" == "ollama-args:run llama3.2:3b hello" ]] || fail "chat did not call 'ollama run' with the default model: $out"
ok "chat uses ollama run and the default model"

HOME="$HOME_DIR" bash "$REPO_ROOT/samurai/scripts/samurai-ai" credentials set openai sk-test >/dev/null
[[ "$(HOME="$HOME_DIR" bash "$REPO_ROOT/samurai/scripts/samurai-ai" credentials get openai)" == "sk-test" ]] \
    || fail "credential get failed"
HOME="$HOME_DIR" bash "$REPO_ROOT/samurai/scripts/samurai-ai" credentials remove openai >/dev/null
if [[ -f "$HOME_DIR/.config/samurai/credentials" ]] && grep -q 'openai' "$HOME_DIR/.config/samurai/credentials"; then
    fail "credential remove left data behind"
fi
ok "file credential fallback round-trips"

# 5. Theme CLI installs a real .colors file and supports the set alias
HOME="$HOME_DIR" SAMURAI_THEME_DIR="$REPO_ROOT/samurai/themes" \
    bash "$REPO_ROOT/samurai/scripts/samurai-theme" set kuro >/dev/null
assert_file "$HOME_DIR/.local/share/color-schemes/samurai-kuro.colors"
grep -q '^ColorScheme=samurai-kuro$' "$HOME_DIR/.local/share/color-schemes/samurai-kuro.colors" \
    || fail "Kuro scheme has the wrong ColorScheme key"
[[ "$(HOME="$HOME_DIR" bash "$REPO_ROOT/samurai/scripts/samurai-theme" status | head -n 1)" == "Selected theme: kuro" ]] \
    || fail "theme status did not report kuro"
ok "theme installs to the KDE color-schemes directory"

# 5b. Both KDE schemes parse and carry the expected scheme name
if command -v python3 >/dev/null 2>&1; then
    python3 - "$REPO_ROOT" <<'PY'
import configparser
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
for theme in ("kuro", "shiro"):
    path = root / "samurai" / "themes" / theme / f"samurai-{theme}.colors"
    parser = configparser.ConfigParser()
    parser.read(path)
    assert parser["General"]["ColorScheme"] == f"samurai-{theme}", path
    for section in ("Colors:Window", "Colors:View", "Colors:Button"):
        assert parser.has_section(section), f"{path}: missing {section}"
PY
    ok "KDE color schemes parse"
fi

# 5c. Calamares branding and package wiring are present
branding="$REPO_ROOT/build/config/includes.chroot/etc/calamares/branding/samurai"
assert_file "$branding/branding.desc"
for asset in productLogo.png productIcon.png productWelcome.png slide1.png show.qml; do
    assert_file "$branding/$asset"
done
grep -q '^componentName:.*samurai$' "$branding/branding.desc" || fail "Calamares component name is missing"
grep -q '^calamares$' "$REPO_ROOT/build/config/package-lists/samurai.list.chroot" || fail "calamares is not installed"
grep -q '^calamares-settings-debian$' "$REPO_ROOT/build/config/package-lists/samurai.list.chroot" \
    || fail "calamares-settings-debian is not installed"
for pkg in grub-pc-bin grub-efi-amd64-bin efibootmgr; do
    grep -q "^$pkg$" "$REPO_ROOT/build/config/package-lists/samurai.list.chroot" \
        || fail "$pkg is not installed for the installer"
done
grep -q 'branding: samurai' "$REPO_ROOT/build/config/hooks/normal/0100-samurai.hook.chroot" \
    || fail "Calamares branding is not selected"
assert_file "$REPO_ROOT/build/verify-iso.sh"
grep -q 'bash build/verify-iso.sh' "$REPO_ROOT/.github/workflows/build-iso-hosted.yml" \
    || fail "hosted workflow does not verify ISO contents"
ok "Calamares installer configuration is present"

# 6. Gaming launcher strips the subcommand before passing arguments
mkdir -p "$TMP/bin"
cat > "$TMP/bin/steam" <<'EOF'
#!/bin/sh
printf 'steam-args:%s\n' "$*"
EOF
chmod 0755 "$TMP/bin/steam"
out=$(PATH="$TMP/bin:$PATH" HOME="$HOME_DIR" bash "$REPO_ROOT/samurai/scripts/samurai-gaming" steam --foo)
[[ "$out" == "steam-args:--foo" ]] || fail "steam launcher passed the wrong args: $out"
ok "gaming launcher forwards only user arguments"

# 7. Post-build helpers fail clearly without arguments
if bash "$REPO_ROOT/scripts/analyze-iso.sh" >/dev/null 2>&1; then
    fail "analyze-iso.sh should fail without an ISO path"
fi
bash "$REPO_ROOT/scripts/post-build-workflow.sh" --help >/dev/null
ok "post-build helpers have usable interfaces"

# 8. live-build config emits the documented option names
mkdir -p "$TMP/fakelb" "$TMP/lbwork"
cat > "$TMP/fakelb/lb" <<'EOF'
#!/bin/sh
printf '%s\n' "$*"
EOF
chmod 0755 "$TMP/fakelb/lb"
out=$(cd "$TMP/lbwork" && PATH="$TMP/fakelb:$PATH" bash "$REPO_ROOT/build/auto/config")
assert_contains "$out" "--architecture amd64" "config architecture"
assert_contains "$out" "--binary-image iso-hybrid" "config binary image"
assert_contains "$out" "--debian-installer none" "config installer"
assert_contains "$out" "--archive-areas main contrib non-free-firmware" "config archive areas"
ok "live-build config uses valid option names"

printf '\nAll %d smoke checks passed.\n' "$pass"
