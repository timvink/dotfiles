// Proxy auto-config: route my headless dev boxes through their per-box SSH SOCKS
// proxy so http://devbox:<port> (and homelab) load in the browser. Everything
// else goes DIRECT, so normal browsing is untouched.
//
// The SOCKS proxies come up only while connected: the `devbox` alias adds
// `-D 1080`, the homelab ssh config adds `DynamicForward 1081`. With Firefox's
// network.proxy.socks_remote_dns=true the hostname is resolved AT the box, which
// maps `devbox`/`homelab` to its own loopback (/etc/hosts) → the dev server.
//
// Managed by chezmoi. Referenced by ~/.config (Firefox user.js sets the
// autoconfig_url to file://<this file>).
function FindProxyForURL(url, host) {
    if (host === "devbox")  return "SOCKS5 127.0.0.1:1080";
    if (host === "homelab") return "SOCKS5 127.0.0.1:1081";
    return "DIRECT";
}
