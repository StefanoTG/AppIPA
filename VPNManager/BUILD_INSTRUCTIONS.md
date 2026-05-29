# VPN Manager — Build & Install Instructions

## Requirements
- Mac with macOS 13+
- Xcode 15 or later (free on Mac App Store)
- Apple ID (free — no paid developer account needed for personal use via AltStore/Sideloading)

---

## Step 1 — Open in Xcode

1. Download and unzip `VPNManager.zip`
2. Open `VPNManager.xcodeproj` (double-click or drag into Xcode)
3. Xcode will open the project automatically

---

## Step 2 — Set Your Apple ID (Signing)

1. In Xcode, click **VPNManager** in the left sidebar (the blue project icon)
2. Select the **VPNManager** target
3. Go to **Signing & Capabilities** tab
4. Under **Team**, click the dropdown and sign in with your **Apple ID**
   - Use any Apple ID (even a free one)
5. Xcode will automatically register the app with a unique bundle ID

> If you see a "Failed to register bundle identifier" error, change the Bundle Identifier to something unique, e.g. `com.yourname.VPNManager`

---

## Step 3A — Run Directly on Your iPhone (Easiest)

1. Connect your iPhone via USB cable
2. In the top toolbar, select your iPhone as the build target
3. Press **Cmd+R** or click the **Run (▶)** button
4. On your iPhone, go to **Settings → General → VPN & Device Management**
5. Find your Apple ID and tap **Trust**
6. The app will open on your phone

This method works for **7 days** with a free Apple ID (re-sign when it expires).

---

## Step 3B — Export as IPA (for AltStore / Sideloady)

### Export the IPA:
1. In Xcode menu: **Product → Archive**
   - Make sure your iPhone or "Any iOS Device (arm64)" is selected as the target, NOT a simulator
2. Wait for archive to complete — the **Organizer** window opens
3. Click **Distribute App**
4. Choose **Custom** → **Direct Distribution** → **Export**
5. Choose a save location — you'll get a `.ipa` file

### Install via AltStore (no jailbreak):
1. Install **AltStore** on your Mac: [altstore.io](https://altstore.io)
2. Install **AltStore** on your iPhone via the Mac app
3. Open AltStore on iPhone → **My Apps** tab → **+** button
4. Select your `.ipa` file
5. App installs — valid for 7 days, refresh with AltStore

### Install via Sideloady (Windows/Mac):
1. Download **Sideloady**: [sideloadly.io](https://sideloadly.io)
2. Connect iPhone, open Sideloady
3. Drag your `.ipa` into Sideloady
4. Enter Apple ID and password → click **Start**

---

## Step 3C — 1-Year IPA with Paid Apple Developer Account ($99/year)

1. In **Signing & Capabilities**, select your paid team
2. **Product → Archive → Distribute App → App Store Connect → Export**
3. Or use **Ad Hoc** distribution for direct IPA installation
4. This gives you a full 1-year certificate

---

## Features in This App

- Dashboard with income totals and overdue alerts
- Customer list with search and filters (All / Active / Due Soon / Expired / Not Extended)
- Add/Edit customers with full fields
- Customer detail with Extended / Didn't Extend buttons
- Auto-advances payment date by 1 month on "Extended"
- Payment history log
- Local notifications: day-of and 1-day-before reminders
- Face ID / Touch ID lock screen
- Passwords stored in iOS Keychain (encrypted)
- JSON backup export and import
- Dark mode with indigo/purple design
- 6 sample customers preloaded on first launch

---

## Requirements

- iOS 17.0 or later
- iPhone (optimized for iPhone, portrait orientation)

---

## Troubleshooting

**"Untrusted Developer" on iPhone:**
→ Settings → General → VPN & Device Management → Trust your Apple ID

**Build error "No signing certificate":**
→ Signing & Capabilities → Team → select your Apple ID

**SwiftData error on first run:**
→ Delete the app from your iPhone and reinstall — this clears the database

**Notifications not showing:**
→ Settings → Notifications → VPN Manager → Allow Notifications
