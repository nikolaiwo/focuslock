# FocusLock Homebrew Cask Distribution

## Overview

Automated Homebrew Cask distribution for FocusLock via a personal tap. Pushing a version tag triggers a GitHub Actions workflow that builds, releases, and updates the Cask formula automatically.

## Repository Structure

Two repositories:
- `nikolaiwo/focus-lock` - App source code + release workflow
- `nikolaiwo/homebrew-focuslock` - Homebrew tap with Cask formula

Tap structure:
```
homebrew-focuslock/
└── Casks/
    └── focuslock.rb
```

User installation:
```bash
brew install nikolaiwo/focuslock/focuslock
```

## GitHub Actions Workflow

**Trigger:** Push tag matching `v*` (e.g., `v1.0.0`)

**Steps:**
1. Checkout repo at tagged commit
2. Install XcodeGen
3. Build Release configuration (`xcodegen && xcodebuild`)
4. Zip `FocusLock.app`
5. Create GitHub Release with zip attached
6. Clone tap repo, update formula version + SHA256, commit and push

**Required secret:** `HOMEBREW_TAP_TOKEN` - PAT with write access to tap repo

## Cask Formula

```ruby
cask "focuslock" do
  version "1.0.0"
  sha256 "abc123..."

  url "https://github.com/nikolaiwo/focus-lock/releases/download/v#{version}/FocusLock.zip"
  name "FocusLock"
  desc "Menu bar app that prevents blocked apps from stealing window focus"
  homepage "https://github.com/nikolaiwo/focus-lock"

  app "FocusLock.app"

  zap trash: [
    "~/Library/Preferences/com.focuslock.app.plist",
  ]
end
```

## Setup Checklist

1. Create `nikolaiwo/homebrew-focuslock` repo with initial Cask formula
2. Create GitHub PAT with `Contents: Read and write` for tap repo
3. Add `HOMEBREW_TAP_TOKEN` secret to focus-lock repo
4. Add `.github/workflows/release.yml` to focus-lock
5. Update README with installation instructions and Gatekeeper workaround

## Release Process

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Notes

- No code signing/notarization - users need to right-click → Open on first launch or run `xattr -cr /Applications/FocusLock.app`
- Starting version: v1.0.0
