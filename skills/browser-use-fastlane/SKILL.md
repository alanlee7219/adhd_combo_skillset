---
name: browser-use-fastlane
description: "Fast browser automation for public, no-login web tasks via browser-use on oci-dev-01: about 3-7 seconds per task instead of a minute. Use for public pages needing a real browser; never for logged-in, account, or payment tasks."
---

# Browser-Use Fast Lane (oci-dev-01)

Fast browser automation for PUBLIC, no-login web tasks, running browser-use 1.0.6
on oci-dev-01. Measured 2026-11-19: a two-site task (GitHub repo page + example.com,
with extraction) took 2.6s warm / 4.4s cold, vs under a minute via Muse's built-in
browser delegation. Use it to cut latency on repetitive public-site work.

## When to use

- Public pages that need real browser rendering or interaction (JS-heavy pages,
  clicking, form-free navigation, structured extraction).
- Repetitive checks where the built-in browser's delegation overhead dominates.

## When NOT to use

- Anything needing the user's logged-in sessions, saved logins, Secure Vault,
  Wallet/payment approval, or account identity (Facebook Marketplace, Gmail,
  bookings, purchases). Those stay on Muse's built-in browser or connectors.
- A plain HTTP fetch or an official API can answer it — use that instead; it is
  faster than any browser.
- Never enter credentials, OTPs, or payment data through this lane. Its Chromium
  profile is a fresh throwaway profile with no logins.

## How it runs

- Runtime lives on oci-dev-01 (direct egress; Muse's own VM cannot use it —
  that VM's egress proxy rejects Chromium CONNECT tunnels).
- A wrapper starts a Playwright Chromium with its own profile and a local
  remote-debugging port, and browser-use is routed to it via BU_CDP_WS.
  Do NOT rely on browser-use's own-Chromium auto-start: on this machine it dies
  with a ProcessSingleton permission error. Always go through bu_exec.sh.
- Telemetry is disabled in the executor (ANONYMIZED_TELEMETRY=false).

### From Muse (this agent)

```bash
~/workspace/custom-skills/browser-use-fastlane/scripts/bu_run.sh <task.py> [--keep]
```

bu_run.sh copies the task file to oci-dev-01 (ubuntu account, ~/browser-use-pilot)
over the Tailscale SSH relay and runs bu_exec.sh there. Default: Chromium and the
browser-use daemon are stopped after the run. `--keep` leaves them warm for an
immediate follow-up task.

### From an OpenMausBot bot (already on oci-dev-01, maus account)

```bash
~/browser-use-pilot/bu_exec.sh <task.py> [--keep]
```

Same executor in the maus home (port 9224). No SSH needed.

## Writing a task file

Task files are Python fed to `browser-use` on stdin. Helpers are pre-imported.

```python
import time
new_tab("https://example.com")          # first navigation is new_tab, not goto_url
wait_for_load()
time.sleep(1)                            # SPAs often need a beat after load
print("TITLE:", js("document.title"))
print("TEXT:", js("document.body.innerText.slice(0, 500)"))
goto_url("https://example.org")          # later navigations use goto_url
wait_for_load()
```

Rules:
- Extract with innerText / visible text first. Site-specific ids and selectors
  rot quickly (GitHub's logged-out layout already dropped the star-counter id);
  fall back to attribute selectors, then to innerText matching.
- Print only the data the task needs. Keep total output under ~10 KB.
- One task per file; reuse the tab instead of opening duplicates.
- The executor prints `BU_ELAPSED_MS=<n> RC=<rc>` as the last line — report it.

## Setup / repair (already installed; only if broken)

On oci-dev-01, per account (ubuntu for Muse, maus for the bots):

```bash
sudo apt-get install -y python3.12-venv libatomic1   # once per machine
python3 -m venv ~/browser-use-pilot/venv
~/browser-use-pilot/venv/bin/pip install 'browser-use==1.0.6' playwright
~/browser-use-pilot/venv/bin/playwright install chromium
```

Pin browser-use exactly (`==1.0.6`, never `>=`): releases move fast and break APIs.
chrome-wrapper.sh and bu_exec.sh live in ~/browser-use-pilot next to the venv.
Verify with a task against https://example.com and check BU_ELAPSED_MS prints RC=0.
