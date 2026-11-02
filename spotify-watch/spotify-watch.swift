// spotify-watch — mirror "is Spotify playing?" into the Karabiner variable
// `spotify_playing` (1/0), so the volume-key rule in karabiner.json only routes
// to Spotify while it plays and leaves the native keys (HUD, no lag) otherwise.
//
// Event-driven, no polling: Spotify posts the distributed notification
// com.spotify.client.PlaybackStateChanged on every play/pause/stop, and
// NSWorkspace reports when Spotify quits (which posts nothing).
//
// On start it only clears the variable when Spotify isn't running. If Spotify
// is already running, the variable Karabiner still holds stays as it was, and
// the next play/pause corrects it. Querying Spotify directly would need an
// Automation (Apple Events) permission prompt for this binary.
//
// Compiled into ~/.local/libexec/spotify-watch by
// .chezmoiscripts/run_onchange_after_setup-spotify-watch_darwin.sh.tmpl and
// kept running by the com.timvink.spotify-watch LaunchAgent.

import AppKit

let karabinerCLI = "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"
let spotifyBundleID = "com.spotify.client"

func setPlaying(_ playing: Bool) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: karabinerCLI)
    process.arguments = ["--set-variables", "{\"spotify_playing\":\(playing ? 1 : 0)}"]
    do {
        try process.run()
        process.waitUntilExit()
    } catch {
        FileHandle.standardError.write("spotify-watch: \(error)\n".data(using: .utf8)!)
    }
}

DistributedNotificationCenter.default().addObserver(
    forName: Notification.Name("com.spotify.client.PlaybackStateChanged"),
    object: nil, queue: .main
) { note in
    setPlaying((note.userInfo?["Player State"] as? String) == "Playing")
}

NSWorkspace.shared.notificationCenter.addObserver(
    forName: NSWorkspace.didTerminateApplicationNotification,
    object: nil, queue: .main
) { note in
    let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
    if app?.bundleIdentifier == spotifyBundleID { setPlaying(false) }
}

if NSRunningApplication.runningApplications(withBundleIdentifier: spotifyBundleID).isEmpty {
    setPlaying(false)
}

RunLoop.main.run()
