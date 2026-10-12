# v1.1.4 Beta — release blocked

Review date: 2026-10-13. Android is the primary target. This is a coherent
data-safety/mobile-layout batch, not completion of the full hardening specification.

## Feature inventory and repair priority

| Feature | Status and evidence |
| --- | --- |
| Prayer logging, notes, nested Qaza | Implemented and unit verified; real-device restart/upgrade pending |
| Home timetable and caution countdown | Implemented and unit verified; approximate boundaries, not official timings |
| Analytics and district filters | Implemented and unit verified; dataset provenance unresolved |
| Backup migration / merge / replace | Implemented and unit verified; native device workflow pending |
| Native share/picker | Implemented; bridge tests and Flutter analysis, physical-device verification pending |
| Tasbih counting / targets | Missing in active WebView; existing completion flag only |
| Separate reflection notebook | Missing; existing per-prayer notes retained |
| Notifications | Dormant Dart implementation; not integrated with canonical Vue engine |
| Bilingual guidance | Implemented; unsupported accuracy claims corrected; scholarly review pending |
| SQLite/native calculations | Dormant distinct implementations, preserved for investigation, not deleted |
| Android compatible update | Package preserved, certificate continuity and actual update unverified |

Priority: finish data safety and native smoke tests; verify official Bangladesh
timing/geography; scholarly review; complete existing missing workflows; device
QA; only then public signing/release.

## This batch

- Fail-closed SQLite migration: no invented timestamps, bool coercions, empty
  fallback datasets or orphan relationship loss.
- Validate preferences before writes; preview plus explicit merge/replace;
  recoverable multi-key restore and blocked startup on failed recovery.
- Native share acknowledgement and JSON picker; no false saved-file message.
- Bilingual Home caution countdown, active versus upcoming estimates.
- Mobile 44px button targets, three-column date grid on narrow phones, readable
  Help prose, wrapping district selection/filter controls and compact timetable
  rows. District selection preserves method/madhab and reports save failures.
- Removed unsupported IFB approval, verified-coordinates, 1–2 minute tolerance,
  universally greatest-reward and unconditional upgrade-preservation claims.
- Preserved Android `com.example.mobile` namespace/applicationId and WebView
  loading mechanism. Release now requires existing signing credentials; debug
  is never an automatic release fallback. CI only produces debug verification
  APKs and no longer automatically tags/publishes releases.

## Release blockers

1. Obtain the actual v1.1.3 distributed APK and certificate/key continuity
   evidence. Version metadata is `1.1.4-beta.1+6`, but prior artifact versionCode
   must be inspected. Do not regenerate a key or uninstall to work around this.
2. Verify all district reference points and division/name metadata with primary
   geography. Current data is community-sourced, not government-verified.
3. Official IFB seasonal/Ramadan/district timetable fixtures and justified
   tolerances are absent. A fetch of `https://islamicfoundation.gov.bd` failed
   with a transport error in this batch; no values or official convention were
   invented. The default remains adhan Karachi (18° Fajr/Isha), Hanafi Asr;
   it is not claimed to match IFB. Library rounding/adjustments and high-latitude
   behavior need a complete sourced methodology audit.
4. Qualified scholarly review of guidance and approximate caution intervals.
5. Physical Android native share/import, offline startup, storage exhaustion,
   lifecycle/keyboard/text scaling and actual upgrade smoke tests.
6. Active Tasbih counter, standalone notes and canonical-engine notifications
   are not completed. Do not advertise them as tested working features.

## Verification

Web: **76 tests passed in 12 files**. Flutter: **10 tests passed** and analysis
reported no issues. Type check, ESLint and Oxlint passed. Production single-file
web bundle built (2,482.36 kB, gzip 1,030.73 kB) and copied to the mobile assets.
The HTML contains no external script tags or stylesheet links.

Android debug build succeeded: `mobile/build/app/outputs/flutter-apk/app-debug.apk`,
154,333,519 bytes (verification only, not a public release). APK manifest:
`com.example.mobile`, versionCode `6`, versionName `1.1.4-beta.1`, minimum SDK 24,
target SDK 36. Its bundled web asset exactly matched the copied asset; SHA-256
`e680e19dbc6002f06c7daed252101dfff2e9c72774bb736c186a31a99e8e34ba`.
The release build was attempted and correctly failed with the missing-signing
guard. No distributable release APK was produced in this batch.

Incremental Flutter builds initially packaged an older asset despite success.
`flutter clean` and rebuilding resolved this, verified by extracting exact APK
bytes. `scripts/verify-mobile-apk.py` now enforces the match in CI before upload;
a synthetic matching/stale ZIP check passed. Always run it after local builds.
`adb devices` reported no attached devices; no installation/upgrade was attempted.

Browser geometry checks found and repaired a 320px All-Districts overflow.
English tracker retest at 320/360/430px: no page overflow and no visible buttons
smaller than 44px. Bengali Home at 320/360/390/430px had no overflow.
Settings/Qaza/Analytics/Guide were checked at 320/390/430px before final wording
changes. A broader matrix timed out and is not counted as passed. Screenshot
capture was unavailable (“needs a visible tab”); **pixel-perfect visual review
and physical-device QA are not claimed**.

## Tester recovery and release commands

Back up outside the app before testing. Never uninstall as a normal update step.
On migration error, retain app data, free storage and reopen. A lower-version APK
is not a safe rollback strategy; prefer a forward-fixed compatible build and a
validated backup. Never silently clear data.

```sh
bash scripts/build-mobile-web.sh
cd client
npm run type-check
npm run test:unit -- --run
npx eslint .
npx oxlint .
cd ../mobile
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
python3 ../scripts/verify-mobile-apk.py build/app/outputs/flutter-apk/app-debug.apk
# Public build only after blockers are resolved; use the existing certificate:
# IQAMAH_KEYSTORE_PATH, IQAMAH_STORE_PASSWORD, IQAMAH_KEY_ALIAS, IQAMAH_KEY_PASSWORD
flutter build apk --release
```

Linux cannot validate an iOS signing/build path. No public release is authorized
by passing unit tests or building a debug verification APK.

See [backup and recovery](backup-and-recovery.md) for schema and transaction boundaries.
