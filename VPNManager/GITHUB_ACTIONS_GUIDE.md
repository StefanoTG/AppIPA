# How to Build Your IPA via GitHub Actions

No Mac needed. GitHub provides free macOS build machines.

---

## Step 1 — Create a GitHub Account

Go to [github.com](https://github.com) and create a free account if you don't have one.

---

## Step 2 — Create a New Repository

1. On GitHub, click **+** → **New repository**
2. Name it `VPNManager`
3. Set it to **Private** (your data stays private)
4. **Do NOT** check "Add README"
5. Click **Create repository**

---

## Step 3 — Upload the Project

On your computer (Windows, Mac, or Linux):

### Option A — GitHub Desktop (easiest, no terminal)
1. Download [GitHub Desktop](https://desktop.github.com)
2. Sign in with your GitHub account
3. Go to **File → Add Local Repository**
4. Browse to the `VPNManager` folder you extracted
5. Click **Publish repository** → choose your `VPNManager` repo
6. Click **Push origin**

### Option B — Command line (Mac/Linux)
```bash
cd /path/to/VPNManager
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR_USERNAME/VPNManager.git
git push -u origin main
```

---

## Step 4 — Watch the Build

1. Go to your repository on GitHub
2. Click the **Actions** tab
3. You'll see **Build VPN Manager IPA** running (takes ~5–10 minutes)
4. Wait for the green checkmark ✅

---

## Step 5 — Download Your IPA

1. Click on the completed workflow run
2. Scroll down to **Artifacts**
3. Click **VPNManager-IPA** to download a zip
4. Extract the zip — you'll find `VPNManager.ipa` inside

---

## Step 6 — Install the IPA on Your iPhone

Since this IPA is unsigned (no Apple certificate), you need a tool to sign and install it. Choose one:

### Sideloady (Windows or Mac) — Recommended
1. Download from [sideloadly.io](https://sideloadly.io)
2. Connect your iPhone via USB
3. Open Sideloady, drag `VPNManager.ipa` into it
4. Enter your Apple ID and password
5. Click **Start** — done!

### AltStore (Mac or Windows)
1. Install AltStore server on your computer from [altstore.io](https://altstore.io)
2. Install AltStore app on your iPhone
3. In AltStore on your iPhone → **My Apps** → **+** → select the IPA

### Esign / GBox (on-device, no computer)
1. Install Esign from a trusted source
2. Import the IPA file
3. Sign with a free certificate and install

---

## Rebuild When Expired (every 7 days with free Apple ID)

The workflow runs automatically every time you push. To trigger it manually:
1. GitHub → **Actions** tab
2. Click **Build VPN Manager IPA**
3. Click **Run workflow** → **Run workflow**
4. Download new IPA → re-install with Sideloady

---

## Notes

- The IPA is **unsigned** — signing happens when you install via Sideloady/AltStore using your Apple ID
- Your code is in a **private** repo — no one can see it
- Build is 100% free (GitHub gives 2,000 free macOS minutes/month)
- The app data stays only on your iPhone — no server involved
