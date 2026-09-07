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
no active extension → no host → dead socket. Walk the user through it, in order:

- **Enable it** (installed but switched off): Firefox → `about:addons` →
  Extensions → toggle **Proton LLM Bridge** on → reload the `mail.proton.me` tab.
- **Re-load it** (was only a temporary add-on — those are wiped on every Firefox
  restart): open `about:debugging#/runtime/this-firefox` → *Load Temporary
  Add-on…* → pick `extension/manifest.json` → reload the Proton tab.
- **Install it permanently** (survives restarts): `make sign` to produce a signed
  `.xpi`, then `about:addons` → gear → *Install Add-on From File…* → pick the
  `.xpi` from `web-ext-artifacts/`. Then reload the Proton tab.

After any of these, `proton-bridge ping` should report `loggedIn: true`.

