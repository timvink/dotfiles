#!/usr/bin/env bash
# env-vault-sync.sh — keep a .env file mirrored into the Vaultwarden vault (rbw).
#
# Run `update` after a .env changes to (re)write the vault copy; `check` compares
# the two without writing. Reading a .env needs no sync — only editing does. The
# whole .env lives in the NOTES of a Login-type rbw item named
# "env-backup:<repo-name>/<path-relative-to-repo-root>" (e.g.
# "env-backup:timvink-homelab/.env"), so the SAME repo's .env maps to the SAME
# entry on every machine/checkout (macOS vs Linux vs a git worktree all differ
# in absolute path). Outside a git repo it falls back to "<dir-name>/<file>".
# See the `vault` skill (SKILL.md alongside this script).
#
# Usage:
#   env-vault-sync.sh check  <path/to/.env>
#   env-vault-sync.sh update <path/to/.env>
#
# `check` exit codes:
#   0  in sync — the vault copy and the .env hold exactly the same keys+values
#   2  vault locked        -> the user must run `rbw unlock`
#   3  drift               -> keys missing/changed in the vault copy (DRIFT), or
#                             left in the vault after being deleted from the .env
#                             (STALE). Both are fixed by `update`.
#   4  no backup yet       -> the item doesn't exist; run `update`
#  64  usage / environment error
#
# Secret VALUES are never printed: drift is reported by KEY NAME only. Temp files
# (update only) are created under $XDG_RUNTIME_DIR when available (RAM-backed on
# the homelab) so the .env never transits the unencrypted OS-drive /tmp.
#
# A Bitwarden note holds at most 10000 encrypted characters (~7 KB of text), so a
# larger .env is split across "<item>", "<item> (part 2)", "<item> (part 3)", ...
# `check` reads every part; `update` rewrites them, removes parts it no longer
# needs, and reads the result back before reporting success.

set -euo pipefail

die() { printf '%s\n' "$*" >&2; exit 64; }

cmd=${1:-}; envpath=${2:-}
[ -n "$cmd" ] && [ -n "$envpath" ] || die "usage: env-vault-sync.sh {check|update} <path/to/.env>"
[ -f "$envpath" ] || die "no such .env: $envpath"

# Find rbw even under a minimal PATH (a patched build in ~/.cargo/bin, or
# Homebrew's bin, which aren't always exported to non-login shells).
rbw=$(command -v rbw || true)
[ -n "$rbw" ] || for c in "$HOME/.cargo/bin/rbw" /opt/homebrew/bin/rbw /usr/local/bin/rbw; do
  [ -x "$c" ] && { rbw="$c"; break; }
done
[ -n "$rbw" ] || die "rbw not found (looked on PATH, ~/.cargo/bin, Homebrew)"

# Stable item name, independent of WHERE the repo is checked out. The .env's
# content is the secret; the name only has to match across machines so the
# backup round-trips. Key on "<repo-name>/<path-relative-to-repo-root>" rather
# than the absolute path (which differs on macOS vs the homelab vs a worktree).
abs="$(cd "$(dirname "$envpath")" && pwd -P)/$(basename "$envpath")"
dir="$(dirname "$abs")"
if root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null); then
  # Normalize linked worktrees to the MAIN worktree's directory name (git lists
  # the main worktree first), so a worktree checkout shares the primary clone's
  # backup entry instead of spawning a near-duplicate.
  main=$(git -C "$dir" worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p;q')
  key="$(basename "${main:-$root}")/${abs#"$root"/}"
else
  # Not in a git repo — fall back to "<parent-dir-name>/<filename>", still
  # independent of the tree's location.
  key="$(basename "$dir")/$(basename "$abs")"
fi
item="env-backup:$key"

# Plaintext bytes per note: Bitwarden's 10000-character cap applies to the
# encrypted, base64-encoded value (~4/3 of the text plus a header).
part_bytes=6500
part_name() { if [ "$1" -eq 1 ]; then printf '%s' "$item"; else printf '%s (part %s)' "$item" "$1"; fi; }

# Every part's notes, in order, one after the other.
vault_note() {
  local n=1 name
  while name=$(part_name "$n") && "$rbw" get "$name" >/dev/null 2>&1; do
    "$rbw" get --field notes "$name" 2>/dev/null || true
    echo
    n=$((n + 1))
  done
}

require_unlocked() {
  "$rbw" unlocked >/dev/null 2>&1 || { echo "vault locked — run: rbw unlock" >&2; exit 2; }
}

# Significant lines only: drop comments and blanks (comments aren't secrets, so
# changing them must not count as drift).
sig() { grep -vE '^[[:space:]]*(#|$)' "$1" 2>/dev/null || true; }

# Compare $1 (current .env) and $2 (vault copy) in BOTH directions, emitting one
# marked key name per line:
#   >KEY  in the .env but missing or different in the vault  -> backup is behind
#   <KEY  still in the vault but no longer in the .env       -> stale secret
#
# The second direction matters: a key you DELETE from a .env stays in the vault
# forever otherwise, and a one-directional check happily reports "in sync" while
# a dead credential sits in the backup. Both conditions are fixed by `update`,
# which rewrites the note wholesale.
#
# Keyed on the text before the first '='; compares whole lines, so a changed
# value counts. Values are never emitted — only key names.
drifted_keys() { # $1=current  $2=vault
  awk -F= 'NR==FNR { cur[$1]=$0; next } { v[$1]=$0 }
           END {
             for (k in cur) if (cur[k] != v[k]) print ">" k
             for (k in v)   if (!(k in cur))    print "<" k
           }' "$1" "$2" | sort
}

case "$cmd" in
  check)
    require_unlocked
    "$rbw" get "$item" >/dev/null 2>&1 || {
      echo "no vault backup for $abs yet — run: env-vault-sync.sh update $envpath" >&2; exit 4; }
    note=$(vault_note)
    keys=$(drifted_keys <(sig "$envpath") <(printf '%s\n' "$note" | grep -vE '^[[:space:]]*(#|$)' || true))
    behind=$(printf '%s\n' "$keys" | sed -n 's/^>//p')
    stale=$(printf '%s\n' "$keys" | sed -n 's/^<//p')
    if [ -n "$behind" ] || [ -n "$stale" ]; then
      if [ -n "$behind" ]; then
        echo "DRIFT — these .env keys are missing or changed in the vault backup:" >&2
        printf '  %s\n' $behind >&2
      fi
      if [ -n "$stale" ]; then
        echo "STALE — these keys are still in the vault backup but no longer in the .env:" >&2
        printf '  %s\n' $stale >&2
      fi
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
    # Significant lines only: rbw strips '#' lines from the buffer anyway, and
    # blanks would only spend the note's size cap.
    sig "$envpath" | awk -v max="$part_bytes" -v dir="$tmpd" '
      BEGIN { n = 1; size = 0 }
      { len = length($0) + 1
        if (len > max) { bad = 1; exit }
        if (size + len > max && size > 0) { n++; size = 0 }
        print > (dir "/part." n); size += len }
      END { if (bad) exit 9; print n > (dir "/count") }' \
      || die "a line of $envpath is longer than $part_bytes bytes, which no vault note can hold"
    parts=$(cat "$tmpd/count")
    buf="$tmpd/buf"; writer="$tmpd/writer"
    # rbw opens $VISUAL/$EDITOR with the entry's tempfile as $1; this writer just
    # drops our prepared buffer into it (non-interactive).
    printf '#!/bin/sh\ncp "%s" "$1"\n' "$buf" > "$writer"; chmod +x "$writer"
    created=0
    for n in $(seq 1 "$parts"); do
      name=$(part_name "$n")
      # Line 1 becomes rbw's "password" field (a self-documenting marker); the
      # rest becomes the notes.
      { printf '%s\n' "env-backup [$key] part $n/$parts ($abs) — managed by env-vault-sync.sh; edit the real .env, then: update"
        cat "$tmpd/part.$n"; } > "$buf"
      # rbw edit/add are editor-driven and HANG without a controlling terminal,
      # so run them under a pseudo-tty. The writer needs no real input, so a
      # /dev/null stdin is fine.
      if "$rbw" get "$name" >/dev/null 2>&1; then sub=edit; else sub=add; created=1; fi
      EDITOR="$writer" VISUAL="$writer" python3 -c \
        'import pty,sys; sys.exit(0 if pty.spawn(sys.argv[1:])==0 else 1)' \
        "$rbw" "$sub" "$name" </dev/null || die "rbw $sub failed for: $name"
    done
    n=$((parts + 1))
    while name=$(part_name "$n") && "$rbw" get "$name" >/dev/null 2>&1; do
      "$rbw" remove "$name" || die "could not remove the unused part: $name"
      n=$((n + 1))
    done
    "$rbw" sync >/dev/null 2>&1 || true
    # Read it back: an unverified backup is not a backup.
    keys=$(drifted_keys <(sig "$envpath") <(vault_note | grep -vE '^[[:space:]]*(#|$)' || true))
    [ -z "$keys" ] || { echo "update did not take: the vault copy still differs from $abs" >&2; exit 1; }
    [ "$created" = 1 ] && [ "$parts" = 1 ] && echo "created vault backup for $abs" \
      || echo "updated vault backup for $abs ($parts part(s))"
    ;;

  *) die "unknown command: $cmd (expected check|update)" ;;
esac
