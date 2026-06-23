#!/usr/bin/env bash
# env-vault-sync.sh — keep a .env file mirrored into the Vaultwarden vault (rbw).
#
# A "linter" gate for .env files: before any secret in a .env is used, `check`
# confirms the vault holds a current copy; `update` (re)writes that copy. The
# whole .env lives in the NOTES of a Login-type rbw item named
# "env-backup:<abs-path>", so rbw can both read and write it. See the `vault`
# skill (SKILL.md alongside this script).
#
# Usage:
#   env-vault-sync.sh check  <path/to/.env>
#   env-vault-sync.sh update <path/to/.env>
#
# `check` exit codes:
#   0  in sync — every .env key is present in the vault with a matching value
#   2  vault locked        -> the user must run `rbw unlock`
#   3  drift               -> some keys missing/changed in the vault copy
#   4  no backup yet       -> the item doesn't exist; run `update`
#  64  usage / environment error
#
# Secret VALUES are never printed: drift is reported by KEY NAME only. Temp files
# (update only) are created under $XDG_RUNTIME_DIR when available (RAM-backed on
# the homelab) so the .env never transits the unencrypted OS-drive /tmp.

set -euo pipefail

die() { printf '%s\n' "$*" >&2; exit 64; }

cmd=${1:-}; envpath=${2:-}
[ -n "$cmd" ] && [ -n "$envpath" ] || die "usage: env-vault-sync.sh {check|update} <path/to/.env>"
[ -f "$envpath" ] || die "no such .env: $envpath"

# Find rbw even under a minimal PATH (it lives in ~/.cargo/bin on Linux and
# Homebrew's bin on macOS, which aren't always exported to non-login shells).
rbw=$(command -v rbw || true)
[ -n "$rbw" ] || for c in "$HOME/.cargo/bin/rbw" /opt/homebrew/bin/rbw /usr/local/bin/rbw; do
  [ -x "$c" ] && { rbw="$c"; break; }
done
[ -n "$rbw" ] || die "rbw not found (looked on PATH, ~/.cargo/bin, Homebrew)"

# Stable item name, independent of the caller's cwd.
abs="$(cd "$(dirname "$envpath")" && pwd -P)/$(basename "$envpath")"
item="env-backup:$abs"

require_unlocked() {
  "$rbw" unlocked >/dev/null 2>&1 || { echo "vault locked — run: rbw unlock" >&2; exit 2; }
}

# Significant lines only: drop comments and blanks (comments aren't secrets, so
# changing them must not count as drift).
sig() { grep -vE '^[[:space:]]*(#|$)' "$1" 2>/dev/null || true; }

# Print the names of keys that are missing-or-changed in $2 (vault) relative to
# $1 (current .env). Keyed on the text before the first '='; compares whole
# lines, so a changed value counts. Values are never emitted — only key names.
drifted_keys() { # $1=current  $2=vault
  awk -F= 'NR==FNR { cur[$1]=$0; next } { v[$1]=$0 }
           END { for (k in cur) if (cur[k] != v[k]) print k }' "$1" "$2" | sort
}

case "$cmd" in
  check)
    require_unlocked
    "$rbw" get "$item" >/dev/null 2>&1 || {
      echo "no vault backup for $abs yet — run: env-vault-sync.sh update $envpath" >&2; exit 4; }
    note=$("$rbw" get --field notes "$item" 2>/dev/null) || note=""
    keys=$(drifted_keys <(sig "$envpath") <(printf '%s\n' "$note" | grep -vE '^[[:space:]]*(#|$)' || true))
    if [ -n "$keys" ]; then
      echo "DRIFT — these .env keys are missing or changed in the vault backup:" >&2
      printf '  %s\n' $keys >&2
      echo "run: env-vault-sync.sh update $envpath  (after rbw unlock)" >&2
      exit 3
    fi
    echo "ok: vault backup current for $abs"
    ;;

  update)
    require_unlocked
    command -v python3 >/dev/null 2>&1 || die "update needs python3 (to drive rbw's editor through a pty)"
    tmpd=$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/env-vault.XXXXXX")
    chmod 700 "$tmpd"; trap 'rm -rf "$tmpd"' EXIT
    buf="$tmpd/buf"; writer="$tmpd/writer"
    # Line 1 becomes rbw's "password" field (a self-documenting marker); the rest
    # becomes the notes — i.e. the verbatim .env.
    { printf '%s\n' "env-backup ($abs) — managed by env-vault-sync.sh; edit the real .env, then: update"
      cat "$envpath"; } > "$buf"
    # rbw opens $VISUAL/$EDITOR with the entry's tempfile as $1; this writer just
    # drops our prepared buffer into it (non-interactive).
    printf '#!/bin/sh\ncp "%s" "$1"\n' "$buf" > "$writer"; chmod +x "$writer"
    # rbw edit/add are editor-driven and HANG without a controlling terminal, so
    # run them under a pseudo-tty. The writer above needs no real input, so a
    # /dev/null stdin is fine.
    if "$rbw" get "$item" >/dev/null 2>&1; then sub=edit; else sub=add; fi
    EDITOR="$writer" VISUAL="$writer" python3 -c \
      'import pty,sys; sys.exit(0 if pty.spawn(sys.argv[1:])==0 else 1)' \
      "$rbw" "$sub" "$item" </dev/null
    "$rbw" sync >/dev/null 2>&1 || true
    [ "$sub" = add ] && echo "created vault backup for $abs" || echo "updated vault backup for $abs"
    ;;

  *) die "unknown command: $cmd (expected check|update)" ;;
esac
