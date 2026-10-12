# Backup and recovery — v1.1.4 beta

Implementation review: 2026-10-13. These are synthetic test fixtures, not personal records.

## Persistence boundary

The active Flutter shell bundles the Vue application at the unchanged
`loadFlutterAsset('assets/web/index.html')` file origin. Pinia reads WebView
LocalStorage. Dormant SQLite code owns a separate `iqamah_local.db`; it is not
opened, cleared or automatically merged by this release. Actual storage-profile
preservation across an Android update remains unverified.

## Schema

`version: "2.0.0"` is a backup schema version, distinct from app version
`1.1.4-beta.1`. Export contains `exportedAt` (ISO timestamp), `appVersion`,
`prayerLogs` (complete history with stable IDs and nested pending/fulfilled Qaza),
and `preferences` (username, language, theme, gender when selected, district,
method and madhab). Prayer records include notes, Tasbih completion flags,
travel/home/Jamaah/Jummah metadata and classifications.

There is no persistent Tasbih counter/target in the active application yet;
the boolean flag must not be advertised as a counter. Separate reflection
notebooks are also not implemented. Countdown state, compiled assets, dormant
native notification state, onboarding gate and last-share metadata are excluded.

Exports are plaintext and sensitive, not encrypted or authenticated. The unused,
unverified custom checksum was removed; structural validation is not a proof
of authenticity. Redundant historical `pendingQazas` is not authoritative;
relationships come from canonical nested Qaza records.

## Historical migration

- Native integer `version: 1`: actual `prayer_logs` / `qaza_logs` table exports,
  camelCase columns, strict integer 0/1 booleans. Preserve timestamps, IDs and
  relationships; reject orphan/duplicate Qaza, missing sections and bad flags.
- Web `version: "1.1.0"`: canonical prayer DTOs, optional historical username
  and gender. Missing preferences remain absent, not fabricated.
- Existing string aliases `"1"` and `"1.0.0"` remain accepted for structurally
  valid canonical records; no distinct historical artifact for these aliases
  has been found. Tests exercise them against the canonical schema.
- Current `"2.0.0"`: canonical records and validated preferences.

Future versions are rejected. Reading does not rewrite the file or local data.
Fixture files under `client/src/__tests__/fixtures/` cover the distinct shapes.

## Restore semantics

Read file → JSON parse → detect/migrate → validate records and preferences →
preview record count and mode → offer current backup → explicit confirmation →
commit → exact storage-value verification → reload stores.

Merge adds records, deduplicates identical stable-ID/day-prayer records and
rejects conflicts. It never applies imported preferences. Replace changes all
prayer records and preferences actually present in the backup; absent historical
preferences remain unchanged. An explicit empty district clears location.

LocalStorage does not offer multi-key transactions. Before any affected key
changes, write `iqamah_restore_journal`, containing the old raw values. All
changes are synchronous, verified, and the journal is removed only on completion.
On I/O failure, roll back. On interruption or rollback failure, startup restores
the old values before initializing stores. If recovery cannot finish, startup
is blocked and the journal remains. Record reads/writes are blocked while a
journal exists. Free device storage and reopen; **do not clear app data**.
The boundary is this WebView profile only; not SQLite or another device/tab.

## Native file handling and evidence

Android/iOS use existing `file_picker` and `share_plus` dependencies. The restricted
file-origin bridge accepts bounded JSON and product filenames, correlates requests,
and acknowledges success/cancellation/error. No arbitrary native path is accepted.
The last-share timestamp is updated only after native success. The OS does not
report a durable destination path; “shared” does not promise permanent storage.
Standalone web reports “download requested”, not a confirmed saved file.

Native plugin/device behavior, permission denial and OS-specific unavailable
share results still require physical-device verification. Unit tests verify
JavaScript acknowledgement and transactional recovery, not the OS share sheet.
