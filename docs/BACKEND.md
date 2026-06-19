# Bora — Backend Design (Phase 2: Sharing)

The goal of this phase: turn mock friends into **real people who join via an
invite link and sync their real busy/free times**, while keeping the privacy
promise (only busy/free, never event details).

## Guiding principle

The overlap engine (`Bora/Services/Availability.swift`) already works
**client-side**. So the backend's *only* job is to store and share busy/free
blocks between friends. The app keeps computing overlaps locally — we just swap
`MockData` for real friend data fetched from the server.

```
Device Calendar (EventKit)  ──push my busy blocks──▶  Supabase
                                                         │
Friends' apps  ◀──pull friends' busy blocks (RLS-gated)─┘
        │
        └─▶ Availability engine (unchanged) ─▶ "Free together" UI
```

## Stack: Supabase

- **Postgres** database + **Auth** + **Row-Level Security** + auto REST API.
- Free tier is plenty for MVP; no servers to run.
- Swift client: the official [`supabase-swift`](https://github.com/supabase/supabase-swift) SPM package.

## Data model (see `supabase/migrations/0001_init.sql`)

| Table         | Purpose                                                        |
|---------------|---------------------------------------------------------------|
| `profiles`    | One row per user: display name, avatar tint, timezone, handle |
| `friendships` | Accepted friend pairs (canonical `user_a < user_b`)           |
| `invites`     | Share-link tokens (`bora.app/i/<token>`), 14-day expiry       |
| `busy_blocks` | Each user's busy intervals (busy/free only — **no details**)  |

### Privacy via Row-Level Security (the important part)

- You can `SELECT` someone's `busy_blocks` **only** if `are_friends(you, them)`.
- You can only write **your own** profile and busy blocks.
- Friendships are created through the `redeem_invite()` function (security
  definer), so invite tokens can't be enumerated by reading the table.

This means privacy is enforced by the database itself, not by app code — even a
malicious client with the public key cannot read a stranger's availability.

## Key flows

**Sign up / sign in** → Supabase Auth issues a session; a `profiles` row is
auto-created by a trigger.

**Add a friend** → Tap "Invite" → app calls `invites` insert → gets a token →
shares `bora.app/i/<token>` via the iOS share sheet. Friend opens the link →
app calls `redeem_invite(token)` → mutual friendship created.

**Sync availability** → On app foreground / calendar change, the app reads
EventKit busy blocks for the next 14 days and **replaces** its own `busy_blocks`
rows (delete window → insert current). Friends' apps pull these on refresh.

**Find time** → Unchanged. The app fetches selected friends' `busy_blocks` and
feeds them into the existing `Availability.commonFreeSlots(...)`.

## Security notes

- The **anon (publishable) key** is safe to embed in the app — RLS protects the
  data. It will live in a gitignored `Bora/Secrets.xcconfig`.
- The **service_role key** must NEVER be shipped in the app or committed. We
  won't need it client-side at all.

## What I need from you (one-time setup)

1. Create a free project at [supabase.com](https://supabase.com) (account +
   project creation is yours to do — it involves credentials).
2. In the project's **SQL Editor**, paste & run `supabase/migrations/0001_init.sql`.
3. Send me the **Project URL** and the **anon/publishable key**
   (Settings → API). These are safe to share; do **not** send the service_role key.

Then I'll build the Swift data layer (`BoraClient`, auth, sync) and wire the UI
to live data.

## Open decision

**Auth method** for sign-in — this affects the onboarding UX and friend
discovery. My recommendation: **Sign in with Apple** for the MVP (native,
frictionless, privacy-friendly, no SMS cost). Phone-based discovery can come
later. See the question in chat.
