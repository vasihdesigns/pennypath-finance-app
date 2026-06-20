# Releasing PennyPath

A short, repeatable checklist for shipping a new version to the App Store
**without breaking the version already on users' devices.**

- **Bundle id:** `com.vasih.PennyPath`
- **Min iOS:** 17.0
- **Scheme:** `PennyPath`

## One-time setup (do once, before the first submission)

1. **Fill in the real links.** Edit [`PennyPath/Features/Settings/SupportLinks.swift`](PennyPath/Features/Settings/SupportLinks.swift) — replace the placeholder `privacyPolicy`, `terms`, `supportEmail`, and `appStoreID` with your real values. The privacy-policy link is **required** by App Store Guideline 5.1.1 and must also be entered in App Store Connect.
2. **Enable iCloud (for iCloud Sync).** The code and an entitlements file are in place, but the CloudKit container must be registered against your Apple Developer account:
   - In Xcode → target **PennyPath** → **Signing & Capabilities** → **+ Capability** → **iCloud** → tick **CloudKit** → confirm the container `iCloud.com.vasih.PennyPath`.
   - This requires a paid Apple Developer account. Until it's enabled, the in-app **iCloud Sync** toggle safely falls back to on-device storage, so the app still works.
   - Face ID (`NSFaceIDUsageDescription`) is already set in build settings — no action needed.

## Versioning

Two numbers, set in the target's build settings (`PennyPath.xcodeproj`):

| Setting | Build-setting key | What it is | When to bump |
|---|---|---|---|
| Marketing version | `MARKETING_VERSION` | The version users see (e.g. `1.1`) | Every public release |
| Build number | `CURRENT_PROJECT_VERSION` | Internal build counter | **Every** upload to App Store Connect, even a re-upload of the same marketing version |

Rules of thumb:
- Bug-fix only → bump the patch/minor marketing version (`1.0` → `1.0.1` / `1.1`).
- New features → bump the minor/major (`1.1` → `1.2` / `2.0`).
- The build number must **always increase** and must be unique per upload, or App Store Connect rejects it.

## Pre-flight checklist

Run through this before every submission:

1. **Tests pass**
   ```bash
   xcodebuild -project PennyPath.xcodeproj -scheme PennyPath \
     -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
   ```
2. **🔴 Schema migration gate (most important for this app).**
   Did this release change anything in `PennyPath/Models/` — add/remove/rename a
   stored property, add a model, change a type? If **yes**, you must add a new
   schema version + migration stage in
   [`PennyPath/Models/PennyPathSchema.swift`](PennyPath/Models/PennyPathSchema.swift)
   before shipping, or existing users can crash or lose data on update. The file
   documents the exact steps. If **no model changes**, nothing to do here.
   - Verify by installing the *previous* App Store build (or a build from the
     last release tag), entering data, then running the new build over it and
     confirming the data survives.
3. **Bump versions** — set `MARKETING_VERSION` and increment `CURRENT_PROJECT_VERSION`.
4. **Privacy & assets** — `PennyPath/PrivacyInfo.xcprivacy` still reflects data
   use (this app: no tracking, no collection); app icon present.
5. **Screenshots / App Store Connect metadata** updated if the UI changed.
6. Working tree clean and merged to `main`.

## Build, archive, submit

In Xcode: select **Any iOS Device**, then **Product ▸ Archive**, and use the
Organizer to **Distribute App ▸ App Store Connect**.

Or from the command line:

```bash
# 1. Archive
xcodebuild -project PennyPath.xcodeproj -scheme PennyPath \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath build/PennyPath.xcarchive archive

# 2. Export + upload (needs an ExportOptions.plist with method = app-store-connect)
xcodebuild -exportArchive -archivePath build/PennyPath.xcarchive \
  -exportOptionsPlist ExportOptions.plist -exportPath build/export
```

Then finish review submission in App Store Connect.

## Tag the release in git

Tag the exact commit on `main` that you submitted, so every store version maps
to a commit and you can always rebuild or diff against it. Do this **after** the
build is uploaded.

```bash
git checkout main
git pull
git tag -a v1.0 -m "PennyPath 1.0 (build 1) — App Store"
git push origin v1.0
```

Use the marketing version for the tag name (`v1.0`, `v1.1`, …). For a re-upload
of the same marketing version with a new build, append the build (`v1.0-b2`).

## After release

- Note the version/build and the tag in your release notes.
- If you changed the schema, keep the old `PennyPathSchemaV<n>` definitions in
  the codebase — they are the contract with data still on older installs.
