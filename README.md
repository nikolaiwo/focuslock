# FocusLock

A macOS menu bar app that prevents blocked apps from stealing window focus.

## Features

- Monitor and log all focus changes
- Block specific apps from stealing focus (default: SecurityAgent)
- Automatically restore focus to your previous app when a blocked app tries to activate
- Optional notifications when blocking occurs
- Launch at login support

## Installation

### Homebrew (recommended)

```bash
brew install nikolaiwo/focuslock/focuslock
```

### Manual

Download the latest release from the [Releases page](https://github.com/nikolaiwo/focuslock/releases), unzip, and drag `FocusLock.app` to your Applications folder.

## First Launch (unsigned app)

Since FocusLock is not signed with an Apple Developer certificate, macOS Gatekeeper will block it on first launch. To open it:

1. Right-click (or Control-click) on FocusLock in Applications
2. Select "Open" from the context menu
3. Click "Open" in the dialog that appears

Or run this command to clear the quarantine flag:
```bash
xattr -cr /Applications/FocusLock.app
```

## Usage

FocusLock runs in your menu bar. Click the lock icon to:

- **Toggle Protection** - Enable/disable focus blocking
- **Toggle Notifications** - Get notified when apps are blocked
- **View Focus Log** - See all focus changes and add apps to blocklist
- **Blocked Apps** - Manage your blocklist
- **Launch at Login** - Start FocusLock automatically

## Why?

Some apps (like macOS SecurityAgent for password prompts) aggressively steal focus, interrupting your workflow. FocusLock prevents this by immediately restoring focus to your previous app.

## Requirements

- macOS 13.0 (Ventura) or later

## License

MIT
