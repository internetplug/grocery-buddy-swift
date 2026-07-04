# GroceryBuddy (iOS)

SwiftUI iPhone app for building grocery lists and routing an efficient path through the store. Departments live on a fully customizable store map — drag, resize, add, and delete zones — and the app computes the shortest route through every department that still has items to pick up.

## Features

- **Shopping list** grouped by department, with quantities, check-off progress, filters (all/pending/done), and per-department suggestions learned from your history.
- **Customizable store map** — drag/resize department zones, add custom departments with their own emoji and color, save/load multiple map layouts (e.g. different stores).
- **Route planning** — pick an entrance and get an optimized stop order (exact Held–Karp TSP for ≤ 12 stops, nearest-neighbor + 2-opt beyond that), with manual reordering. The active route survives app restarts.
- **Saved item lists** — snapshot and reload recurring lists (weekly run, party run…).
- **Optional account sync** — email/password auth with the entire state synced to a Cloudflare Worker. The app is fully usable offline/logged out; local and cloud data are merged on sign-in (never overwritten).

## Architecture

```
┌────────────────────────┐        HTTPS (cookies)        ┌──────────────────────────┐
│  GroceryBuddy (iOS)    │ ────────────────────────────► │  grocery-buddy-api        │
│  SwiftUI · iOS 17+     │   /api/auth/*  /api/user-data │  Cloudflare Worker        │
│  UserDefaults (local)  │ ◄──────────────────────────── │  Hono · better-auth       │
└────────────────────────┘                               │  Kysely · D1 (SQLite)     │
                                                         └──────────────────────────┘
```

- **App state**: a single `AppViewModel` (`ObservableObject`) holds items, categories, map layout, saved slots, history, and the active route. Every change is persisted to `UserDefaults` via `LocalStore`, and — when signed in — debounced (1.5 s) and uploaded in full by `CloudSync`.
- **Sync model**: last-write-wins full-state upload, with a union merge on login (local edits win per record; additions are never lost). Failed uploads surface in the Account sheet and retry when the app returns to the foreground.
- **Auth**: better-auth session cookie, scoped to the API host. The last-known user is cached locally so an offline launch keeps you "signed in" visually.
- **Backend**: lives in a separate repo — `../grocery-buddy-api/grocery-buddy-api` (Cloudflare Worker: Hono + better-auth + Kysely on D1, database `grocery_buddy`). Deployed at `https://grocery-buddy-api.ariel-q64623.workers.dev`.

### API endpoints used by the app

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/auth/sign-up/email` | Create account |
| POST | `/api/auth/sign-in/email` | Sign in |
| POST | `/api/auth/sign-out` | Revoke session |
| GET | `/api/auth/get-session` | Restore session on launch |
| GET | `/api/user-data` | Download full app state |
| POST | `/api/user-data` | Upload full app state |

## Repository layout

```
GroceryBuddy/
├── GroceryBuddyApp.swift      # App entry; foreground sync-retry hook
├── Info.plist                 # APIBaseURL (from the API_BASE_URL build setting)
├── Models/                    # Codable models, default categories & map layout
├── ViewModels/AppViewModel.swift
├── Networking/                # AuthClient (URLSession actor), CloudSync (merge + debounce)
├── Storage/LocalStore.swift   # UserDefaults persistence
├── Utilities/                 # RouteComputer (TSP), Color helpers
└── Views/                     # SwiftUI screens and sheets
CODE_AUDIT.md                  # Security/UX audit and implementation status
```

## Requirements

- Xcode 17+ (project targets **iOS 17.0**, Swift 5)
- No external Swift dependencies — plain `xcodebuild` works
- For the backend: Node 20+ and Wrangler (`npx wrangler`)

## Build & run

### Xcode

Open `GroceryBuddy.xcodeproj`, select the **GroceryBuddy** scheme, and run on a simulator or device.

### Command line

```bash
# Build for the simulator
xcodebuild -project GroceryBuddy.xcodeproj -scheme GroceryBuddy \
  -destination 'generic/platform=iOS Simulator' build

# Build and run on a specific simulator
xcrun simctl boot "iPhone 16"   # once
xcodebuild -project GroceryBuddy.xcodeproj -scheme GroceryBuddy \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
xcrun simctl install booted \
  ~/Library/Developer/Xcode/DerivedData/GroceryBuddy-*/Build/Products/Debug-iphonesimulator/GroceryBuddy.app
xcrun simctl launch booted com.grocerybuddy.io
```

> If `xcodebuild` complains about Command Line Tools, point it at the full Xcode:
> `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
> (or prefix commands with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`).

### API base URL

`AuthClient` picks its backend automatically:

- **Simulator builds** → `http://localhost:8787` (the local Wrangler dev server).
- **Device/Release builds** → the `APIBaseURL` Info.plist key, which resolves from the `API_BASE_URL` build setting in `project.pbxproj` (currently the deployed Worker URL). Change it there to point at a different deployment.

## Backend: run & deploy

From `../grocery-buddy-api/grocery-buddy-api`:

```bash
npm install

# Local dev server on http://localhost:8787 (what simulator builds talk to)
npm run dev

# Apply D1 migrations (local dev database / production)
npx wrangler d1 migrations apply grocery_buddy --local
npx wrangler d1 migrations apply grocery_buddy --remote

# Tests
npm test

# Deploy to Cloudflare
npm run deploy
```

## Testing a full flow locally

1. `npm run dev` in the API repo (leaves Wrangler on port 8787).
2. Run the app in the **simulator** (it targets localhost automatically).
3. Sign up, add items, edit the map — changes sync ~1.5 s after the last edit.
4. The Account sheet shows live sync status (synced / syncing / failed-with-retry).

## Notes & conventions

- All persistence keys are prefixed `gb_` in `UserDefaults`.
- Item history is capped at 500 entries; the whole state is synced as one JSON document, so keep payload growth in mind when adding new synced collections.
- `CODE_AUDIT.md` documents the security review, applied fixes, and the deliberately deferred items (Keychain session storage, dark mode, full Dynamic Type).
