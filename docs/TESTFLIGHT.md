# Shipping Bora to friends via TestFlight

Everything in the project is ready (app icon, unique bundle id, signing set to
automatic). These are the steps that need your Apple ID / account.

## 0. Prerequisite — enrol in the Apple Developer Program (you)

- Go to <https://developer.apple.com/programs/enroll/> and enrol (**$99/year**).
- Activation is usually a few hours, occasionally up to ~2 days.
- Use the same Apple ID you'll sign in with in Xcode.

## 1. Sign the app in Xcode (once enrolled)

1. Open `Bora.xcodeproj`.
2. Select the **Bora** target → **Signing & Capabilities** tab.
3. Tick **Automatically manage signing**.
4. Pick your **Team** from the dropdown (your name / RafaVelaro).
5. Bundle Identifier is `com.rafavelaro.bora` — change it if you like, but it
   must be globally unique. Xcode registers the App ID for you.

## 2. Archive

1. In the top toolbar, set the run destination to **Any iOS Device (arm64)**
   (not a simulator — archives require a device target).
2. Menu: **Product → Archive**. Wait for it to build (~1–2 min).
3. The **Organizer** window opens with your archive.

## 3. Upload to App Store Connect

1. In Organizer, select the archive → **Distribute App**.
2. Choose **TestFlight & App Store** → **Upload** → keep the defaults
   (automatic signing) → **Upload**.

## 4. Set up TestFlight (appstoreconnect.apple.com)

1. Go to <https://appstoreconnect.apple.com> → **Apps**.
2. If no Bora app exists yet: **＋ → New App**
   - Platform: iOS · Name: **Bora** (must be unique on the App Store — if taken,
     use e.g. "Bora — Plan Together") · Language: English · Bundle ID:
     `com.rafavelaro.bora` · SKU: `bora-001`.
3. Open the **TestFlight** tab. Your uploaded build appears after ~5–15 min of
   processing. Fill in **Test Information** (what to test + a contact email).
4. Add testers:
   - **Internal testers** (you + up to 100 people you add to App Store Connect):
     builds are available immediately, **no review**. Fastest for close friends
     you can add by Apple ID.
   - **External testers** (anyone, by email or a **public link**): the first
     build of each version needs a quick **Beta App Review** (usually < 24h).
     Best for inviting a wider friend group — share the public link, they
     install the **TestFlight** app, tap the link, get Bora.

## Notes

- Bump the **build number** for every new upload
  (`CURRENT_PROJECT_VERSION` in the project, currently `1`).
- The temporary **email + password** login works fine in TestFlight. Swap it for
  real magic-link / Sign-in-with-Apple before any public launch.
- Friends sync their own real calendars on first launch (calendar permission
  prompt) — the privacy promise (busy/free only) applies to everyone.
