# Shared plumbing for the `homelab` and `devbox` session scripts in ~/.local/bin:
# the image-paste window marker, terminal-mode recovery, dead-master cleanup and the
# reverse ~/Downloads mount. Sourced, not run; bash only (arrays).
#
# Several helpers take a RESOLVER: the name of a function that sets the global array
# REMOTE_DEST to the ssh destination args for the session's master (OPTIONS FIRST,
# host last — ssh stops parsing options at the destination) and returns non-zero
# when there is no usable connection to address. homelab's is a fixed host alias;
# devbox's is resolved off the live master, since the VM's IP changes.
REMOTE_DEST=()

# Mark THIS terminal window (Ghostty or Rex) as being in a session on <host>, so its ⌘V uploads a
# clipboard image to that box instead of handing it to a local app. Pass the host
# to mark, nothing to clear. ssh-image-paste reads it back.
#
# The channel is OSC 7, the escape a shell uses to tell the terminal its working
# directory: we report a marker path instead, .../remote-window/<host>, and
# Ghostty hands it back per surface as the window's AXDocument (Rex per pane, via its CLI). That makes the
# mark per WINDOW, which a file next to the cm-*.sock files could never be — with
# one global flag, a devbox open in one window sent an image ⌘V in another, local
# window to the box and typed back a path this Mac doesn't have.
#
# The marker directory is never created. A new tab opened from a marked window
# inherits its cwd, and inheriting a real one would mark that fresh local tab too.
#
# Clearing is belt-and-braces: Ghostty's shell integration reports $PWD at every
# prompt anyway, so the marker cannot outlive the session even if a script is
# killed outright. Both scripts still clear it from their EXIT traps. See
# ~/.local/bin/ssh-image-paste.
REMOTE_WINDOW_MARK="$HOME/.ssh/remote-window"
_remote_window() {
  if [ -n "${1:-}" ]; then
    printf '\033]7;file://%s%s/%s\a' "$(hostname)" "$REMOTE_WINDOW_MARK" "$1" > /dev/tty 2>/dev/null
  else
    printf '\033]7;file://%s%s\a' "$(hostname)" "$PWD" > /dev/tty 2>/dev/null
  fi
}

# tmux eats OSC 7 instead of forwarding it, so a session started inside a tmux
# pane can't mark its window and its ⌘V stays local. Say so once, on the way in,
# rather than let the upload silently not happen.
_remote_window_warn_tmux() {
  [ -n "${TMUX:-}" ] && printf '%s\n' "$1: inside tmux — an image ⌘V will paste locally, not upload" >&2
  return 0
}

# Undo terminal modes a remote program (tmux, vim) switched on and never got to switch
# off because the connection dropped. Without this, Ghostty keeps reporting every mouse
# move to the local shell, which prints them as ^[[<35;x;yM garbage. Turns off mouse
# tracking (1000/1002/1003, SGR 1006, urxvt 1015), focus events (1004), bracketed paste
# (2004), the alternate screen (1049) and application cursor keys, pops the kitty
# keyboard protocol and shows the cursor; then discards reports already queued on the
# tty. Called right after ssh returns, before the slow unmount, so few reports pile up.
_term_restore() {
  [ -t 1 ] || return 0
  printf '\033[?1000l\033[?1002l\033[?1003l\033[?1006l\033[?1015l\033[?1004l\033[?2004l\033[?1049l\033[?1l\033>\033[<u\033[?25h' > /dev/tty 2>/dev/null
  sleep 0.05
  perl -MPOSIX -e 'tcflush(0, TCIFLUSH)' < /dev/tty 2>/dev/null
  return 0
}

# Drop a ControlPersist master that has no live connection left under it. The trigger is
# a dropped network — this Mac's public IP changes (network switch, roam, sleep/wake), or
# the link just dies: the master process survives with its socket in place, and `ssh -O
# check` still answers "Master running" because it only ever asks that local process,
# never the network. The next session would ride that socket straight into a black hole
# and hang indefinitely: no error, and no ExitOnForwardFailure to catch it either, since a
# mux client requests no forwards of its own. Only a real round trip can tell it apart
# from a healthy one. The masters' ServerAliveInterval makes them exit on their own ~60s
# after the network goes, but not while the Mac slept through it; this covers that window.
# $1=tag (names the mount pidfile) $2=master socket $3=resolver.
_ssh_drop_dead_master() {
  local tag=$1 sock=$2 resolve=$3 name
  [ -S "$sock" ] || return 0
  # The probe has to be bounded or the check becomes the hang it is meant to prevent;
  # without `timeout` (coreutils) don't ask at all, and let the connect take its chances.
  command -v timeout >/dev/null 2>&1 || return 0
  "$resolve" || return 0
  timeout 8 ssh -n -o BatchMode=yes "${REMOTE_DEST[@]}" true 2>/dev/null && return 0
  printf '%s\n' "$tag: the previous session's master is unreachable — dropping it" >&2
  timeout 5 ssh -O exit "${REMOTE_DEST[@]}" 2>/dev/null
  # -O exit asks a master that may itself be wedged, so don't trust it alone: kill whatever
  # still rides that socket (the master, and the reverse-mount bridge multiplexed over it —
  # one was found still hung 1h39m after its connection died), then clear the socket and the
  # local half of the mount so the reconnect starts from nothing. The box's half is left to
  # _revmount's lazy unmount: talking to the box now would ride the same dead connection.
  name=${sock##*/}
  pkill -f "${name//./\\.}" 2>/dev/null
  rm -f "$sock"
  _revumount "$tag"
}

## Reverse ~/Downloads mounts
# `devbox` and `homelab` auto-mount this Mac's ~/Downloads onto the box as
# ~/mac-downloads for the life of the session, so from a remote shell you can just
# `cp ~/mac-downloads/foo.xlsx .` to pull a Mac file onto the box — no separate
# command to run or remember. It's a *reverse* sshfs: the FUSE mount lives on the
# Linux box (it has /dev/fuse + fusermount3); sshfs there runs in slave mode
# (-o slave), speaking SFTP over stdin/stdout instead of dialing out. On this side,
# `dpipe` (from the `vde` brew) wires the box's sshfs to our built-in
# /usr/libexec/sftp-server, so nothing new has to listen on the Mac — it all rides
# the SSH ControlMaster the session script already set up. Mounted read-write so
# it also works the other way: `downloadfile <path>` on the box (~/.local/bin) copies
# a file INTO ~/mac-downloads and it lands in this Mac's ~/Downloads. Needs sshfs on
# each box (run_onchange_setup_packages_linux.sh) and vde on the Mac
# (.chezmoiscripts/…_darwin.sh).

# Bring up the bridge once. $1=tag (names the pidfile); rest = ssh destination args.
# No-op if dpipe is absent (e.g. on a Linux box) or the bridge is already up. The
# remote sh expands ~ and $(id …) on the box; "$macdl" (the Mac's Downloads path) is
# spliced in literally for the slave-mode sshfs to serve.
_revmount() {
  local tag="$1"; shift
  local pidfile="$HOME/.ssh/revmount-$tag.pid" macdl="$HOME/Downloads"
  command -v dpipe >/dev/null 2>&1 || return 0
  [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile" 2>/dev/null)" 2>/dev/null && return 0
  # Force-clear any stale mountpoint before mounting. An abrupt teardown (laptop sleep,
  # network drop, `pkill`-ing the master) kills the bridge without unmounting the box's
  # sshfs, leaving a wedged FUSE mount at ~/mac-downloads. Since it lives inside $HOME,
  # the next login shell HANGS the moment its prompt/rc stats ~. A lazy unmount (-z)
  # detaches it even while "busy" so the fresh sshfs re-mounts cleanly; it's a harmless
  # no-op when nothing is mounted. This makes reconnect self-healing.
  dpipe /usr/libexec/sftp-server = \
    ssh -o RequestTTY=no -o BatchMode=yes "$@" \
      'fusermount3 -uz ~/mac-downloads 2>/dev/null || fusermount -uz ~/mac-downloads 2>/dev/null; mkdir -p ~/mac-downloads && exec sshfs :'"$macdl"' ~/mac-downloads -o slave,reconnect,uid=$(id -u),gid=$(id -g)' &
  echo $! > "$pidfile"
}

# Background waiter: poll (~30s) until the resolver names a live master, then mount.
# The resolver is re-run on each poll because devbox's destination isn't known until
# az brings the master up. Launch with a trailing &. $1=tag $2=resolver.
_revmount_bg() {
  command -v dpipe >/dev/null 2>&1 || return 0
  local tag=$1 resolve=$2 i
  for i in $(seq 1 60); do
    if "$resolve" && ssh -O check "${REMOTE_DEST[@]}" 2>/dev/null; then
      _revmount "$tag" "${REMOTE_DEST[@]}"
      return 0
    fi
    sleep 0.5
  done
}

# Tear down tag's bridge: unmount on the box (best effort — killing the local bridge
# also EOFs the box's sshfs so it self-unmounts) then drop the local processes.
# $1=tag; rest = ssh dest args (may be empty if the box is no longer reachable).
#
# This runs on the way OUT of a session, so it must never be able to block the shell
# you're returning to — and it used to. The remote unmount is the only step in the
# whole exit path that talks to the box, and when that connection is a black hole
# (VM deallocated under us, laptop slept, network switched) ssh waits forever:
# silently, since stderr is dropped, and holding the terminal's stdin. Exiting the
# session then looks like a frozen terminal with only Ctrl-C to escape. Hence:
#   timeout 10        hard ceiling; over a live connection this takes well under 1s.
#   -n                stdin from /dev/null, so a stalled ssh can't eat keystrokes.
#   ConnectTimeout=5  bounds the fallback path when the master socket is already gone.
#   -uz               lazy unmount, same as _revmount: against a stalled-but-alive
#                     sshfs a plain umount(2) blocks in the kernel, while MNT_DETACH
#                     returns at once and still frees ~/mac-downloads — which matters,
#                     because a mount left wedged hangs the box's NEXT login shell
#                     (see _revmount).
# Keepalives would only shorten the stall, not remove it, so the ceiling is the fix.
# Without `timeout` (coreutils: brew on macOS, base on Linux) skip the remote unmount
# rather than reintroduce the hang — _revmount's -uz heals the leftover on reconnect.
_revumount() {
  local tag="$1"; shift
  local pidfile="$HOME/.ssh/revmount-$tag.pid" pid rc
  if [ $# -gt 0 ] && command -v timeout >/dev/null 2>&1; then
    timeout 10 ssh -n -o BatchMode=yes -o ConnectTimeout=5 "$@" \
      'fusermount3 -uz ~/mac-downloads 2>/dev/null || fusermount -uz ~/mac-downloads 2>/dev/null' 2>/dev/null
    rc=$?
    [ "$rc" = 124 ] && printf '%s\n' \
      "note: remote unmount of ~/mac-downloads timed out — it clears on next connect" >&2
  fi
  if [ -f "$pidfile" ]; then
    pid="$(cat "$pidfile" 2>/dev/null)"
    [ -n "$pid" ] && { kill "$pid" 2>/dev/null; pkill -P "$pid" 2>/dev/null; }
    rm -f "$pidfile"
  fi
}
