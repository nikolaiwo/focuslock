# Homebrew Cask Distribution Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Set up automated Homebrew Cask distribution so pushing a version tag creates a release and updates the tap.

**Architecture:** GitHub Actions workflow in focus-lock triggers on version tags, builds the app, creates a GitHub Release, then updates the Cask formula in a separate homebrew-focuslock tap repository.

**Tech Stack:** GitHub Actions, XcodeGen, xcodebuild, Homebrew Cask, gh CLI

---

### Task 1: Create the Homebrew Tap Repository

**Context:** Homebrew taps are just GitHub repos with a specific naming convention (`homebrew-<name>`). The Cask formula goes in `Casks/` directory.

**Step 1: Create the tap repository on GitHub**

Run:
```bash
gh repo create homebrew-focuslock --public --description "Homebrew tap for FocusLock"
```

Expected: Repository created at `nikolaiwo/homebrew-focuslock`

**Step 2: Clone the tap repository**

Run:
```bash
cd /Users/nikolai/priv && git clone git@github.com:nikolaiwo/homebrew-focuslock.git && cd homebrew-focuslock
```

Expected: Empty repository cloned

**Step 3: Create the Casks directory and initial formula**

Create file `Casks/focuslock.rb`:
```ruby
cask "focuslock" do
  version "1.0.0"
  sha256 "PLACEHOLDER"

  url "https://github.com/nikolaiwo/focus-lock/releases/download/v#{version}/FocusLock.zip"
  name "FocusLock"
  desc "Menu bar app that prevents blocked apps from stealing window focus"
  homepage "https://github.com/nikolaiwo/focus-lock"

  depends_on macos: ">= :ventura"

  app "FocusLock.app"

  postflight do
    # Clear quarantine flag for unsigned app
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/FocusLock.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Preferences/com.focuslock.app.plist",
  ]
end
```

**Step 4: Commit and push the initial formula**

Run:
```bash
cd /Users/nikolai/priv/homebrew-focuslock && git add Casks/focuslock.rb && git commit -m "feat: add initial FocusLock cask formula" && git push origin main
```

Expected: Formula pushed to tap repository

---

### Task 2: Create GitHub Personal Access Token

**Context:** The release workflow in focus-lock needs to push to homebrew-focuslock. This requires a PAT with write access.

**Step 1: Create a fine-grained PAT**

1. Go to: https://github.com/settings/tokens?type=beta
2. Click "Generate new token"
3. Name: `HOMEBREW_TAP_TOKEN`
4. Expiration: 90 days (or longer)
5. Repository access: "Only select repositories" → select `homebrew-focuslock`
6. Permissions: Contents → "Read and write"
7. Click "Generate token"
8. Copy the token value

**Step 2: Add the token as a repository secret**

1. Go to: https://github.com/nikolaiwo/focus-lock/settings/secrets/actions
2. Click "New repository secret"
3. Name: `HOMEBREW_TAP_TOKEN`
4. Value: paste the token from Step 1
5. Click "Add secret"

---

### Task 3: Create the GitHub Actions Release Workflow

**Context:** This workflow triggers on version tags, builds the app, creates a release, and updates the tap.

**Files:**
- Create: `.github/workflows/release.yml`

**Step 1: Create the workflows directory**

Run:
```bash
mkdir -p /Users/nikolai/priv/focus-lock/.github/workflows
```

**Step 2: Create the release workflow file**

Create file `/Users/nikolai/priv/focus-lock/.github/workflows/release.yml`:
```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build-and-release:
    runs-on: macos-14

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install XcodeGen
        run: brew install xcodegen

      - name: Generate Xcode project
        run: xcodegen generate

      - name: Build Release
        run: |
          xcodebuild -project FocusLock.xcodeproj \
            -scheme FocusLock \
            -configuration Release \
            -derivedDataPath build \
            CODE_SIGN_IDENTITY="-" \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO

      - name: Package app
        run: |
          cd build/Build/Products/Release
          zip -r FocusLock.zip FocusLock.app

      - name: Calculate SHA256
        id: sha
        run: |
          SHA=$(shasum -a 256 build/Build/Products/Release/FocusLock.zip | awk '{print $1}')
          echo "sha256=$SHA" >> $GITHUB_OUTPUT

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          files: build/Build/Products/Release/FocusLock.zip
          generate_release_notes: true

      - name: Update Homebrew tap
        env:
          HOMEBREW_TAP_TOKEN: ${{ secrets.HOMEBREW_TAP_TOKEN }}
        run: |
          VERSION=${GITHUB_REF_NAME#v}
          SHA256=${{ steps.sha.outputs.sha256 }}

          git clone https://x-access-token:${HOMEBREW_TAP_TOKEN}@github.com/nikolaiwo/homebrew-focuslock.git tap
          cd tap

          sed -i '' "s/version \".*\"/version \"${VERSION}\"/" Casks/focuslock.rb
          sed -i '' "s/sha256 \".*\"/sha256 \"${SHA256}\"/" Casks/focuslock.rb

          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add Casks/focuslock.rb
          git commit -m "chore: bump FocusLock to ${VERSION}"
          git push
```

**Step 3: Commit the workflow**

Run:
```bash
cd /Users/nikolai/priv/focus-lock && git add .github/workflows/release.yml && git commit -m "ci: add release workflow for Homebrew distribution"
```

Expected: Workflow committed locally

---

### Task 4: Create README with Installation Instructions

**Files:**
- Create: `README.md`

**Step 1: Create the README**

Create file `/Users/nikolai/priv/focus-lock/README.md`:
```markdown
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

Download the latest release from the [Releases page](https://github.com/nikolaiwo/focus-lock/releases), unzip, and drag `FocusLock.app` to your Applications folder.

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
```

**Step 2: Commit the README**

Run:
```bash
cd /Users/nikolai/priv/focus-lock && git add README.md && git commit -m "docs: add README with installation instructions"
```

---

### Task 5: Push Changes and Create First Release

**Step 1: Push all commits to main**

Run:
```bash
cd /Users/nikolai/priv/focus-lock && git push origin main
```

**Step 2: Create and push the v1.0.0 tag**

Run:
```bash
cd /Users/nikolai/priv/focus-lock && git tag v1.0.0 && git push origin v1.0.0
```

Expected: Tag pushed, GitHub Actions workflow triggers

**Step 3: Monitor the release workflow**

Run:
```bash
gh run watch
```

Expected: Workflow completes successfully, creates release, updates tap

**Step 4: Verify the tap was updated**

Run:
```bash
gh api repos/nikolaiwo/homebrew-focuslock/contents/Casks/focuslock.rb --jq '.content' | base64 -d
```

Expected: Formula shows version "1.0.0" and real SHA256 checksum

---

### Task 6: Test the Installation

**Step 1: Tap the repository**

Run:
```bash
brew tap nikolaiwo/focuslock
```

**Step 2: Install FocusLock**

Run:
```bash
brew install --cask focuslock
```

Expected: FocusLock.app installed to /Applications

**Step 3: Launch and verify**

Run:
```bash
open /Applications/FocusLock.app
```

Expected: FocusLock appears in menu bar

**Step 4: Clean up test installation (optional)**

Run:
```bash
brew uninstall --cask focuslock
```
