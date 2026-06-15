#!/bin/sh
# Build & register the "Copy Path" Finder context-menu item.
#
# Unlike an Automator Quick Action (which macOS buries in the "Quick Actions"
# submenu), a *top-level* Finder context-menu entry — like Ghostty's
# "New Ghostty Tab Here" — must come from an .app bundle that provides an
# NSServices service. So we build a tiny LSUIElement Cocoa app that, when the
# service fires, copies the selected items' POSIX paths (newline-separated)
# to the clipboard, then quits.
#
# The app is a build artifact (lives in ~/Applications, not chezmoi-managed);
# this script is the source of truth. run_onchange reruns it whenever its
# contents — including the embedded Swift/Info.plist below — change.
#
# Requires the Swift compiler from the Xcode Command Line Tools. If absent we
# skip with a hint rather than failing the whole `chezmoi apply`.

set -eu

if ! xcrun --sdk macosx --find swiftc >/dev/null 2>&1; then
    echo "Copy Path: swiftc not found (install with 'xcode-select --install'), skipping." >&2
    exit 0
fi

APP="$HOME/Applications/Copy Path.app"
MACOS="$APP/Contents/MacOS"
BIN="$MACOS/CopyPath"

rm -rf "$APP"
mkdir -p "$MACOS"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleExecutable</key>
	<string>CopyPath</string>
	<key>CFBundleIdentifier</key>
	<string>com.timvink.CopyPath</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>Copy Path</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSServices</key>
	<array>
		<dict>
			<key>NSMenuItem</key>
			<dict>
				<key>default</key>
				<string>Copy Path</string>
			</dict>
			<key>NSMessage</key>
			<string>copyPath</string>
			<key>NSRequiredContext</key>
			<dict>
				<key>NSTextContent</key>
				<string>FilePath</string>
			</dict>
			<key>NSSendTypes</key>
			<array>
				<string>NSFilenamesPboardType</string>
				<string>public.plain-text</string>
			</array>
		</dict>
	</array>
</dict>
</plist>
PLIST

SRC="$(mktemp -t copypath).swift"
trap 'rm -f "$SRC"' EXIT

cat > "$SRC" <<'SWIFT'
import Cocoa

// Service provider for the "Copy Path" Finder context-menu item.
final class CopyPathProvider: NSObject {
    @objc func copyPath(_ pboard: NSPasteboard,
                        userData: String?,
                        error: AutoreleasingUnsafeMutablePointer<NSString>?) {
        var paths: [String] = []

        // Preferred: file URLs off the service pasteboard.
        if let urls = pboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            paths = urls.map { $0.path }
        }
        // Fallback: legacy filenames property list.
        if paths.isEmpty,
           let names = pboard.propertyList(
               forType: NSPasteboard.PasteboardType("NSFilenamesPboardType")) as? [String] {
            paths = names
        }

        let text = paths.joined(separator: "\n")
        let out = NSPasteboard.general
        out.clearContents()
        out.setString(text, forType: .string)

        // We were launched solely to handle this; exit so we don't linger.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { NSApp.terminate(nil) }
    }
}

let app = NSApplication.shared
let provider = CopyPathProvider()
app.servicesProvider = provider
// Safety net: quit if launched but no service message arrives.
DispatchQueue.main.asyncAfter(deadline: .now() + 10) { NSApp.terminate(nil) }
app.run()
SWIFT

echo "Copy Path: compiling service app"
xcrun --sdk macosx swiftc -O -framework Cocoa -o "$BIN" "$SRC"

# Ad-hoc sign so macOS is happy to register and launch the service.
codesign --force --sign - "$APP" >/dev/null 2>&1 || true

# Register the bundle with Launch Services and refresh the services cache.
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
[ -x "$LSREGISTER" ] && "$LSREGISTER" -f "$APP" || true
/System/Library/CoreServices/pbs -update 2>/dev/null || true

echo "Copy Path: installed at $APP"
