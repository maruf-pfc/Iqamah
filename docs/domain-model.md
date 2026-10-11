# Iqamah — Domain Model Documentation

> **Audience:** New engineers onboarding to the project.  
> **Last Updated:** 2026-10-11 · **v1.1.3**  
> **Layer:** `client/src/` (Vue 3 / TypeScript) · `mobile/lib/` (Flutter / Dart)

---

## 1. Overview

Iqamah tracks a Muslim user's five daily prayers (**Salawat al-Khams**) with:

- **Granular punctuality** (Waqt-based status)
- **Categorised missed reasons** (excused vs. unexcused)
- **Automatic Qaza obligation tracking** via a domain state machine
- **Resolution analytics** (how long it took to make up missed prayers)

---

## 2. Enumerations

### 2.1 `PrayerName`

The five obligatory daily prayers. Used as the primary classifier in `PrayerLog`.

| Value | Int | Description |
|-------|-----|-------------|
| `Fajr` | 0 | Dawn prayer — before sunrise |
| `Dhuhr` | 1 | Midday prayer — after zenith |
| `Asr` | 2 | Afternoon prayer |
| `Maghrib` | 3 | Sunset prayer |
| `Isha` | 4 | Night prayer |

> **Note:** `IsJummah = true` may only be set on a `Dhuhr` log — this replaces Dhuhr on Fridays for applicable users. Any other prayer with `IsJummah = true` throws a `DomainException`.

---

### 2.2 `WaqtStatus` — Prayer Punctuality

Applicable **only when `IsOffered = true`**. Records how early in the time window the prayer was performed.

| Value | Int | Arabic | Description |
|-------|-----|--------|-------------|
| `AwwalAlWaqt` | 0 | أوّل الوقت | First 15-20 mins after Adhan. Highest reward. |
| `WastAlWaqt` | 1 | وسط الوقت | Middle of the Waqt window. |
| `AkhirAlWaqt` | 2 | آخر الوقت | Near the end of the Waqt. Still valid (Ada'), lower reward. |

> ⚠️ Setting `WaqtStatus` on a missed prayer (`IsOffered = false`) throws a `DomainException`.

---

### 2.3 `MissedReason` — Categorised Missed Prayer Reasons

Applicable **only when `IsOffered = false`**. Drives the Qaza state machine.

#### Excused (Ma'dhur) — No Sin Incurred

| Value | Int | Arabic | Description | Qaza? |
|-------|-----|--------|-------------|-------|
| `ExcusedImpurity` | 0 | حيض / نفاس | Menstruation or post-natal bleeding (Hayd/Nifas) | ❌ **No Qaza** |
| `ExcusedSleep` | 1 | نوم | Unintentional sleep | ✅ Qaza required |
| `ExcusedForgetfulness` | 2 | نسيان | Genuine forgetfulness | ✅ Qaza required |

#### Unexcused (Ghayr Ma'dhur) — Sin Incurred

| Value | Int | Arabic | Description | Qaza? |
|-------|-----|--------|-------------|-------|
| `UnexcusedSituational` | 3 | شُغل | Preoccupied / busy (Shughl) | ✅ Qaza required |
| `UnexcusedLaziness` | 4 | كسل | Deliberate laziness (Kasl) | ✅ Qaza required |
| `UnexcusedDistraction` | 5 | غفلة | Heedlessness (Ghaflah) | ✅ Qaza required |

> **Critical rule:** `ExcusedImpurity` is the **only** missed reason that does NOT auto-create a `QazaLog`. All other reasons incur a Qaza obligation.

---

### 2.4 `QazaState` — Make-Up Prayer Lifecycle

| Value | Int | Description |
|-------|-----|-------------|
| `Pending` | 0 | Obligation incurred, not yet performed. Initial state. |
| `Offered` | 1 | Make-up prayer performed. **Terminal state** (irreversible). |

```
              [PrayerLog.Create with !IsOffered && reason ≠ ExcusedImpurity]
                                    │
                                    ▼
                             ┌──────────────┐
                             │  QazaState   │
                             │   Pending    │
                             └──────┬───────┘
                                    │  QazaLog.Fulfill()
                                    ▼
                             ┌──────────────┐
                             │  QazaState   │
                             │   Offered    │  ← Terminal
                             └──────────────┘
```

---

## 3. Domain Entities

### 3.1 `PrayerLog` — Aggregate Root

**Namespace:** `Iqamah.Domain.Entities`

Represents one Salah record for a specific Waqt on a specific date.

#### Database Fields

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Id` | `uuid` | No | Primary key (auto-generated GUID) |
| `UserId` | `integer` | No | FK to `Users` table |
| `PrayerName` | `smallint` | No | `PrayerName` enum (0–4) |
| `PrayerDate` | `date` | No | Calendar date of the prayer; **indexed** |
| `IsOffered` | `boolean` | No | True = Ada' (on-time) |
| `WaqtStatus` | `smallint` | ✓ | Non-null only when `IsOffered = true` |
| `MissedReason` | `smallint` | ✓ | Non-null only when `IsOffered = false` |
| `IsJamaah` | `boolean` | No | Congregation bonus |
| `IsTraveling` | `boolean` | No | Musafir / traveller state |
| `IsJummah` | `boolean` | No | Friday Jumu'ah (Dhuhr only) |
| `LoggedAt` | `timestamptz` | No | UTC timestamp of creation |
| `UpdatedAt` | `timestamptz` | No | UTC timestamp of last modification |

**Recommended indexes:** `(UserId, PrayerDate)`, `(UserId, PrayerName, PrayerDate)` (unique).

#### Business Rules (enforced in entity)

1. `IsOffered = true` → `WaqtStatus` required, `MissedReason` must be null.
2. `IsOffered = false` → `MissedReason` required, `WaqtStatus` must be null.
3. `IsJummah = true` → `PrayerName` must be `Dhuhr`.
4. `RequiresQaza()` returns `true` iff `!IsOffered && MissedReason ≠ ExcusedImpurity`.
5. On creation, if `RequiresQaza()`, a `PrayerMissedDomainEvent` is raised automatically.

---

### 3.2 `QazaLog` — Child Entity

**Namespace:** `Iqamah.Domain.Entities`

Tracks one outstanding Qaza (make-up prayer) debt linked to its parent `PrayerLog`.

#### Database Fields

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Id` | `uuid` | No | Primary key |
| `PrayerLogId` | `uuid` | No | FK → `PrayerLogs.Id` |
| `UserId` | `integer` | No | Denormalised FK to `Users` (for fast queries) |
| `PrayerName` | `smallint` | No | Copied from parent `PrayerLog` |
| `OriginalPrayerDate` | `date` | No | Date the prayer was originally missed |
| `State` | `smallint` | No | `QazaState` enum: 0=Pending, 1=Offered; **indexed** |
| `CreatedAt` | `timestamptz` | No | When obligation was incurred |
| `FulfilledAt` | `timestamptz` | ✓ | When make-up was performed |
| `TimeToResolution` | `interval` | ✓ | `FulfilledAt - CreatedAt` |

**Recommended indexes:** `(UserId, State)`, `(UserId, PrayerName, State)`.

#### Business Rules (enforced in entity)

1. Created exclusively via `QazaLog.CreatePending(...)` factory.
2. `Fulfill()` transitions `Pending → Offered`, sets `FulfilledAt`, computes `TimeToResolution`, raises `QazaFulfilledDomainEvent`.
3. Calling `Fulfill()` on an already `Offered` log throws `DomainException` (idempotency guard).

---

## 4. Domain Events

| Event | Raised By | Consumer |
|-------|-----------|----------|
| `PrayerMissedDomainEvent` | `PrayerLog.Create(...)` | Application handler creates `QazaLog` |
| `QazaFulfilledDomainEvent` | `QazaLog.Fulfill()` | Application handler updates analytics |

---

## 5. Modifier Flags

| Flag | Entity | Rule |
|------|--------|------|
| `IsJamaah` | `PrayerLog` | Congregation prayer — multiplies reward 27× in Hadith |
| `IsTraveling` | `PrayerLog` | Musafir state — enables Qasr (shortening) and Jam' (combining) |
| `IsJummah` | `PrayerLog` | Friday congregational Dhuhr; only valid on `PrayerName.Dhuhr` |

---

## 6. Client-Side Equivalents

### Web (TypeScript)
Client-side types are located in `client/src/types/prayer.types.ts`.  
As of **v1.1.0**, the web client runs fully offline — all domain logic (Qaza creation, streak calculation, analytics) is re-implemented in `client/src/stores/prayer.ts` using `localStorage`.

Key helpers:
- `PRAYER_LABELS` — display strings
- `WAQT_LABELS` — display strings
- `MISSED_REASON_LABELS` — display strings
- `isExcusedMissedReason(reason)` — type guard
- `requiresQaza(reason)` — state machine rule mirrored on client

### Mobile (Dart / Flutter)
Domain enumerations are mirrored in `mobile/lib/main.dart`:
- `PrayerName` — Fajr, Dhuhr, Asr, Maghrib, Isha
- `WaqtStatus` — AwwalAlWaqt, WastAlWaqt, AkhirAlWaqt
- `MissedReason` — ExcusedImpurity, ExcusedSleep, ExcusedForgetfulness, UnexcusedSituational, UnexcusedLaziness, UnexcusedDistraction

All integer values **must** stay in sync across TypeScript and Dart definitions.

---

## 7. Version History

| Version | Date | Key Domain Change |
|---------|------|-------------------|
| v1.0.0 | 2026-06-11 | Initial domain model — server-side EF Core + PostgreSQL |
| v1.1.1 | 2026-07-03 | WebView container parity migration, hash routing configuration, offline streak fixes |
| v1.1.2 | 2026-07-04 | Single-file bundle integration, local offline Material font embedding |
| v1.1.3 | 2026-10-11 | Home dashboard Salah timetable, 64-district live Waqt tracker, design system tokens |

See [CHANGELOG.md](../CHANGELOG.md) for full release notes.
