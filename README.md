# Bora 🟠

A clean, modern iOS app for planning time together with friends — built for the
Netherlands' "let's-put-it-in-the-agenda" culture.

You connect your existing calendar, add friends, and instantly see when you're
**all free** — no group-chat back-and-forth. Only busy/free times are read;
event titles, locations, and guests stay private.

---

## Status: Phase 1 — runnable foundation

This first slice runs on a real iPhone/simulator and demonstrates the core magic:

- ✅ **Connect your Apple Calendar** (EventKit, iOS 17 full-access prompt)
- ✅ Compute **your free slots** within plannable hours (08:00–23:00, tunable)
- ✅ **Overlap with friends** to find common free windows (mock friends for now)
- ✅ Clean SwiftUI design system (Dutch-orange accent, soft cards)
- ✅ Three tabs: **Today**, **Find Time**, **Friends**

Friends are sample data (`MockData.swift`) until the sharing backend exists.

## Requirements

- **Xcode 16+** (install free from the Mac App Store) — needed to build & run
- iOS 17+ device or simulator

## Run it

1. Open `Bora.xcodeproj` in Xcode.
2. Select an iPhone simulator (e.g. iPhone 15).
3. Press ⌘R.
4. Tap **Connect my calendar** and allow access. Add some events in the
   Calendar app to see your real availability change.

## Project layout

```
Bora/
├─ BoraApp.swift               App entry
├─ DesignSystem/Theme.swift    Colors, spacing, cards, buttons
├─ Models/Models.swift         Friend, FreeSlot, MyAvailability
├─ Services/
│  ├─ Availability.swift       Pure free/busy engine (unit-testable)
│  ├─ CalendarStore.swift      EventKit access + busy blocks
│  ├─ AppModel.swift           Friends + selection state
│  └─ MockData.swift           Sample friends
└─ Features/                   SwiftUI screens (Home, FindTime, Friends, …)
```

The `Availability` engine is pure Foundation, so it compiles and runs without
Xcode (used for quick logic checks during development).

## Roadmap (next phases)

1. **Sharing backend** — accounts, friend invites via share link, syncing each
   friend's real busy/free blocks. (Likely Supabase or a small Swift/Node API.)
2. **Google Calendar** — OAuth + read free/busy so non-Apple calendars work.
3. **Propose & confirm** — turn a found slot into an event everyone accepts.
4. **Group planning** — plan with 3+ people, suggest the best overall window.
5. **Polish** — app icon, onboarding, push reminders, Dutch localization.

## Notes

- Name **"Bora"** (Brazilian slang for "let's go!") — pending a pre-launch
  trademark + domain check (e.g. `bora.app` / `getbora.app`).
- Bundle id `com.bora.app` is a placeholder; change it for your Apple
  Developer account.
