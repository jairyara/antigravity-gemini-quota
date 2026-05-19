<div align="center">

# Antigravity Quota

**Your Antigravity IDE + Gemini CLI usage. Live. In the menu bar.**

Stop opening dashboards. Stop wondering if you're about to hit the wall.
A 36-pixel ring tells you everything.

[![Built with Flutter](https://img.shields.io/badge/built%20with-Flutter-02569B?logo=flutter)](https://flutter.dev)
[![macOS](https://img.shields.io/badge/platform-macOS-000?logo=apple)](https://www.apple.com/macos/)
[![Status](https://img.shields.io/badge/status-pre--launch-orange)]()
[![Coming soon to Product Hunt](https://img.shields.io/badge/Product%20Hunt-coming%20soon-da552f?logo=producthunt)]()

</div>

---

## Why this exists

I burned through my Antigravity Pro quota twice in one week without noticing — once mid-deploy, once mid-demo. The web dashboard is two clicks and a context switch away, which means in practice I never check it.

So I built the thing I wanted: **a tiny ring in the menu bar that shows me how much I have left, all the time, without me asking.**

Then I added Gemini CLI usage to the same window, because I live in both.

## What it does

- **Menu bar ring** — circular progress icon shows your most-constrained model quota. The percentage sits next to it. That's it. No notifications, no nags.
- **Click for the popover** — Antigravity + Gemini CLI tabs. Model usage, credit balances (AI / Prompt / Flow), auth status, reset timers.
- **Dashboard view** — 52-week GitHub-style activity heatmap of your daily polling, insights, and quota history.
- **Polls every 5 minutes** — directly talks to the local Antigravity language server (`127.0.0.1`, your machine, your data). Nothing leaves your laptop.
- **Sleeps when you do** — `LSUIElement` app, no dock icon, no taskbar clutter.

## How it works (under the hood, for the curious)

Antigravity ships with a local language server (`language_server_macos`). The app:

1. Finds the running process via `ps`.
2. Extracts its `--csrf_token` and PID.
3. Asks `lsof` which port it's listening on.
4. Calls `https://127.0.0.1:<port>/exa.language_server_pb.LanguageServerService/GetUserStatus` with the CSRF token.

For Gemini CLI: reads `~/.gemini/history/` and `~/.gemini/oauth_creds.json`. No API calls, no network.

Everything happens locally. There is no backend. There is no telemetry.

## Stack

- Flutter desktop (macOS), single binary, ~45 MB
- `tray_manager` + `window_manager` for the menu bar + popover
- `sqflite` for local history (lives in `~/Library/Application Support/`)
- `provider` for state

## Roadmap

- [x] MVP: menu bar ring + popover + dashboard
- [x] Antigravity quota + credits
- [x] Gemini CLI integration
- [ ] Quota reset countdown
- [ ] Notifications when you cross 80% / 95%
- [ ] iOS companion (peek your laptop's quota from your phone)
- [ ] Windows + Linux

## Status

**Pre-launch.** Building in public, polishing for Product Hunt.
Hardened binary, notarized release, and a landing page are next.

If you want to be the first to know when it ships, drop your email here: *(coming soon)*

## Building it yourself

You'll need Flutter (`^3.11.5`) and Xcode.

```bash
git clone https://github.com/<you>/antigravity_quota_app.git
cd antigravity_quota_app
flutter pub get
flutter build macos --release
open build/macos/Build/Products/Release/antigravity_quota_app.app
```

The app sandbox is intentionally **disabled** — it shells out to `ps` and `lsof` to find the Antigravity server. That's also why it ships outside the Mac App Store.

## License

TBD. Pre-launch / personal project. Don't redistribute the built binary yet.

## Author

Built by an indie developer who got tired of running out of tokens at 11pm.
Reach out: **jair.yara11@gmail.com**

---

<div align="center">

*If this saved you from a mid-demo quota wall, that's the whole point.*

</div>
