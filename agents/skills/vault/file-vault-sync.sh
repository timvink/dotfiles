#!/usr/bin/env bash
# file-vault-sync.sh — mirror a whole FILE (binary or text) into the Vaultwarden
# vault (rbw), base64-encoded in the notes of an rbw item.
#
# Companion to env-vault-sync.sh. That one mirrors a .env and compares it
# key-by-key, because a .env is a list of independently-editable secrets. This
# one is for files whose BYTES are the secret and that nothing should ever
# hand-edit: signing keystores, private keys, service-account JSON,
# certificates. There is nothing to diff key-wise, so sync is decided by SHA-256
# of the whole file.
#
# rbw has no attachment support (checked through 1.15), so the bytes ride in the
# notes field as base64. Bitwarden caps a note at 10000 characters, which puts a
# hard ceiling near 7 KB of file — enough for keys and keystores, not for
# archives. `update` refuses anything larger rather than storing a truncated
# copy that only fails on the day you need it.
#
# Item name: "file-backup:<repo-name>/<path-relative-to-repo-root>" (e.g.
# "file-backup:gethumandesign/frontend_android/android.keystore"), keyed the
# same way env-vault-sync.sh keys its items, so the same repo maps to the same
# entry on every machine, checkout and git worktree.
#
# Usage:
#   file-vault-sync.sh check   <path/to/file>
#   file-vault-sync.sh update  <path/to/file>
#   file-vault-sync.sh restore <path/to/file> [--force]
#
# Exit codes (same vocabulary as env-vault-sync.sh):
#   0  in sync / done
#   2  vault locked        -> the user must run `rbw unlock`
#   3  drift               -> the file and the vault copy differ; run `update`
#                             (or `restore`, if the vault copy is the good one)
#   4  no backup yet       -> the item doesn't exist; run `update`
#  64  usage / environment error
#
# File CONTENT is never printed — not on drift, not on error. Only sizes and
# hashes. Temp files are created under $XDG_RUNTIME_DIR when available so the
# plaintext never transits an unencrypted /tmp.

set -euo pipefail

die() { printf '%s\n' "$*" >&2; exit 64; }

cmd=${1:-}; filepath=${2:-}; force=${3:-}
[ -n "$cmd" ] && [ -n "$filepath" ] || die "usage: file-vault-sync.sh {check|update|restore} <path/to/file> [--force]"

# Find rbw even under a minimal PATH (~/.cargo/bin on Linux, Homebrew on macOS).
rbw=$(command -v rbw || true)
[ -n "$rbw" ] || for c in "$HOME/.cargo/bin/rbw" /opt/homebrew/bin/rbw /usr/local/bin/rbw; do
  [ -x "$c" ] && { rbw="$c"; break; }
done
[ -n "$rbw" ] || die "rbw not found (looked on PATH, ~/.cargo/bin, Homebrew)"

# python3 does the base64 and SHA-256 work: `base64`/`sha256sum` spell their
# flags differently on macOS and Linux, and this script has to run on both.
command -v python3 >/dev/null 2>&1 || die "file-vault-sync.sh needs python3"

# Stable item name, independent of WHERE the repo is checked out (see the same
# derivation in env-vault-sync.sh).
abs="$(cd "$(dirname "$filepath")" && pwd -P)/$(basename "$filepath")"
dir="$(dirname "$abs")"
if root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null); then
  # Normalize linked worktrees to the MAIN worktree's directory name, so a
  # worktree shares the primary clone's entry instead of spawning a duplicate.
  main=$(git -C "$dir" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p;q')
  key="$(basename "${main:-$root}")/${abs#"$root"/}"
else
  key="$(basename "$dir")/$(basename "$abs")"
fi
item="file-backup:$key"

require_unlocked() {
  "$rbw" unlocked >/dev/null 2>&1 || { echo "vault locked — run: rbw unlock" >&2; exit 2; }
}

sha_of_file() { python3 -c 'import hashlib,sys;print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$1"; }

# Header lines are prefixed ";" — NOT "#". rbw strips every line starting with
# "#" from the editor buffer (it uses them for the buffer's own instructions),
# so a "#" header silently never reaches the vault. ";" survives, and unlike
# "//" it is not a base64 character, so a header line can never be confused with
# a line of the body.
HDR=';'

# Read a note on stdin, drop the header lines, decode the base64 body, and print
# "<sha256> <bytes>". Exits non-zero on a malformed body.
digest_of_note() {
  python3 -c '
import base64, binascii, hashlib, sys
body = [l for l in sys.stdin.read().splitlines() if not l.lstrip().startswith((";", "#"))]
try:
    raw = base64.b64decode("".join("".join(body).split()), validate=True)
except (binascii.Error, ValueError):
    sys.exit(1)
print(hashlib.sha256(raw).hexdigest(), len(raw))
'
}

case "$cmd" in
  check|update)
    [ -f "$filepath" ] || die "no such file: $filepath"
    ;;
esac

case "$cmd" in
  check)
    require_unlocked
    "$rbw" get "$item" >/dev/null 2>&1 || {
      echo "no vault backup for $abs yet — run: file-vault-sync.sh update $filepath" >&2; exit 4; }
    note=$("$rbw" get --field notes "$item" 2>/dev/null) || note=""
    vault_digest=$(printf '%s\n' "$note" | digest_of_note) || {
      echo "DRIFT — the vault note for $abs is not valid base64 (corrupt or hand-edited)" >&2
      echo "run: file-vault-sync.sh update $filepath" >&2; exit 3; }
    local_sha=$(sha_of_file "$filepath")
    if [ "${vault_digest%% *}" != "$local_sha" ]; then
      echo "DRIFT — the vault backup does not match $abs" >&2
      echo "  local:  $local_sha  ($(wc -c <"$filepath" | tr -d ' ') bytes)" >&2
      echo "  vault:  ${vault_digest%% *}  (${vault_digest##* } bytes)" >&2
      echo "run: file-vault-sync.sh update $filepath   (or restore, if the vault copy is the good one)" >&2
      exit 3
    fi
    echo "ok: vault backup current for $abs ($local_sha)"
    ;;

  update)
    require_unlocked
    bytes=$(wc -c <"$filepath" | tr -d ' ')
    # 10000-char Bitwarden note cap, minus room for the header. Refuse loudly
    # rather than store a copy that silently restores to nothing.
    [ "$bytes" -le 7000 ] || die "file is ${bytes} bytes; a Bitwarden note holds ~7000 bytes of base64-encoded file. Too big for a vault note — back this one up another way."

    tmpd=$(mktemp -d "${XDG_RUNTIME_DIR:-/tmp}/file-vault.XXXXXX")
    chmod 700 "$tmpd"; trap 'rm -rf "$tmpd"' EXIT
    buf="$tmpd/buf"; writer="$tmpd/writer"

    local_sha=$(sha_of_file "$filepath")
    mode=$(python3 -c 'import os,sys;print(oct(os.stat(sys.argv[1]).st_mode & 0o777)[2:].zfill(4))' "$filepath")

    # Line 1 becomes rbw's "password" field (a self-documenting marker); every
    # following line becomes the notes.
    { printf '%s\n' "file-backup [$key] ($abs) — managed by file-vault-sync.sh; restore with: restore"
      printf '%s file-backup: %s\n' "$HDR" "$key"
      printf '%s origin: %s\n' "$HDR" "$abs"
      printf '%s bytes: %s\n' "$HDR" "$bytes"
      printf '%s sha256: %s\n' "$HDR" "$local_sha"
      printf '%s mode: %s\n' "$HDR" "$mode"
      printf '%s encoding: base64\n' "$HDR"
      printf '%s restore: file-vault-sync.sh restore %s\n' "$HDR" "$abs"
      printf '%s\n' "$HDR"
      python3 -c 'import base64,sys;sys.stdout.write(base64.encodebytes(open(sys.argv[1],"rb").read()).decode())' "$filepath"
    } > "$buf"

    # rbw opens $VISUAL/$EDITOR with the entry's tempfile as $1; this writer just
    # drops our prepared buffer into it (non-interactive). rbw edit/add HANG
    # without a controlling terminal, so run them under a pseudo-tty.
    printf '#!/bin/sh\ncp "%s" "$1"\n' "$buf" > "$writer"; chmod +x "$writer"
    if "$rbw" get "$item" >/dev/null 2>&1; then sub=edit; else sub=add; fi
    EDITOR="$writer" VISUAL="$writer" python3 -c \
      'import pty,sys; sys.exit(0 if pty.spawn(sys.argv[1:])==0 else 1)' \
      "$rbw" "$sub" "$item" </dev/null
    "$rbw" sync >/dev/null 2>&1 || true

    # Read the backup back out and re-hash it. An unverified backup is not a
    # backup: if the note was truncated or mangled on the way in, the only
    # honest time to find out is now, not during a restore.
    note=$("$rbw" get --field notes "$item" 2>/dev/null) || note=""
    vault_digest=$(printf '%s\n' "$note" | digest_of_note) || die "verify FAILED: the note read back from the vault is not valid base64"
    [ "${vault_digest%% *}" = "$local_sha" ] || die "verify FAILED: vault copy hashes ${vault_digest%% *}, file hashes $local_sha"
    [ "$sub" = add ] && echo "created vault backup for $abs" || echo "updated vault backup for $abs"
    echo "verified: $local_sha ($bytes bytes, mode $mode) round-trips from the vault"
    ;;

  restore)
    require_unlocked
    "$rbw" get "$item" >/dev/null 2>&1 || { echo "no vault backup named $item" >&2; exit 4; }
    if [ -e "$filepath" ] && [ "$force" != "--force" ]; then
      die "$abs already exists — refusing to overwrite. Re-run with --force if the vault copy is the one you want."
    fi
    note=$("$rbw" get --field notes "$item" 2>/dev/null) || note=""
    want_sha=$(printf '%s\n' "$note" | sed -n "s/^$HDR sha256: //p" | head -1)
    mode=$(printf '%s\n' "$note" | sed -n "s/^$HDR mode: //p" | head -1)
    mkdir -p "$dir"
    printf '%s\n' "$note" | python3 -c '
import base64, os, sys
body = [l for l in sys.stdin.read().splitlines() if not l.lstrip().startswith((";", "#"))]
raw = base64.b64decode("".join("".join(body).split()), validate=True)
path = sys.argv[1]
# Create at 0600 from the start so the plaintext is never briefly world-readable.
fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
with os.fdopen(fd, "wb") as fh:
    fh.write(raw)
' "$abs"
    chmod "${mode:-0600}" "$abs"
    got_sha=$(sha_of_file "$abs")
    if [ -n "$want_sha" ] && [ "$got_sha" != "$want_sha" ]; then
      die "restore FAILED: wrote $got_sha but the note records $want_sha"
    fi
    echo "restored $abs ($(wc -c <"$abs" | tr -d ' ') bytes, mode ${mode:-0600})"
    echo "verified: $got_sha matches the hash recorded in the vault"
    ;;

  *) die "unknown command: $cmd (expected check|update|restore)" ;;
esac
