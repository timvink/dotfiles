# Bridge setup and recovery

Use this when `proton-bridge ping` fails. Installation changes go through the chezmoi setup; first locate the bridge project before using its Makefile targets.


Requires all of:
1. **Firefox open** with a tab on `https://mail.proton.me`, **logged in**.
2. The **Proton LLM Bridge extension** installed, and the **native host** registered
   (`make install-host`, done once during setup).
3. The **`proton-bridge` CLI** on PATH (via `uv tool install ./cli`).

Sanity-check first with `proton-bridge ping`. If it reports `loggedIn: false` or
times out, tell the user what's missing instead of retrying blindly.

A `Connection refused` from `ping` almost always means the **extension isn't
active** in the running Firefox — the native host is spawned by the extension, so
no active extension → no host → dead socket.

First find out which case it is, rather than guessing. Check whether the extension
is installed in any profile at all:

```sh
grep -l 'proton-llm-bridge@local' ~/Library/Application\ Support/Firefox/Profiles/*/extensions.json
```

No match means it was never installed permanently — it was loaded as a temporary
add-on, and those are wiped on every Firefox restart. That is the usual cause of a
bridge that worked yesterday and not today.

**Fix it permanently, don't reload a temporary add-on.** A signed `.xpi` is
normally already sitting in the bridge project's `web-ext-artifacts/`; `make sign`
is only needed when the extension itself changed. Opening that file in Firefox
pops the install prompt directly, which skips the `about:debugging` file-picker
dance:

```sh
open -a Firefox <project>/web-ext-artifacts/<id>-<version>.xpi   # Linux: firefox <path>
```

The user then clicks **Add** in Firefox and reloads the `mail.proton.me` tab.
That click is theirs to make: the assistant's browser automation drives Chrome,
not Firefox, so it cannot reach `about:addons` or an install dialog. Say so
plainly instead of offering to click it.

If a match *was* found, the extension is installed but switched off: Firefox →
`about:addons` → Extensions → toggle **Proton LLM Bridge** on → reload the tab.

After any of these, `proton-bridge ping` should report `loggedIn: true`. A reload
of the Proton tab is often unnecessary once the extension is active — ping before
asking the user for more steps.

