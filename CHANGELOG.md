# Changelog

All notable changes to **Iqamah (إقامة)** are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.1] — 2026-07-03

### Added
- **Mobile — Prayer card emoji icons:** Each prayer row (Fajr 🌙, Dhuhr ☀️, Asr 🌤️, Maghrib 🌅, Isha 🌃) now displays an emoji badge in a rounded container, matching the web client icon design.
- **Mobile — Left status indicator strip:** Each prayer card now has a coloured left-edge strip (green = offered, red = missed, teal = excused/period, grey = unlogged) identical to the web client's vertical accent bar.
- **Mobile — Circular checkbox trailing indicator:** The trailing area of each card shows a filled circular checkmark (✓), error mark (✕), or empty ring that animates on state change, replacing the plain `more_vert` icon.
- **Mobile — Visible edit button:** An `edit_outlined` icon button is always visible in the card trailing area, replacing the hidden long-press-only gesture for opening the logging bottom sheet.
- **Mobile — Responsive 6-column calendar grid:** The horizontal calendar date strip now renders as a full-width `Row` of 6 `Expanded` cells (today + 5 past days), matching the web client's `grid-cols-6` layout.
- **Mobile — Reset Application in Settings:** A new destructive action card in the Settings tab wipes all `prayer_logs` and `qaza_logs` from the SQLite database, clears `SharedPreferences`, and navigates back to the Onboarding screen — identical to the web client's "Reset Application" feature.
- **Web + Mobile — Wave emoji in dashboard greeting:** Dashboard title now reads "আসসালামু আলাইকুম 👋 / Assalamu Alaikum 👋" on both platforms.

### Fixed
- **Mobile — Bengali navigation label:** `navAnalytics` was incorrectly set to the English word `'progress'`; corrected to `'অগ্রগতি'`.
- **Mobile — Calendar future-date bug:** The date strip previously generated days from 3 days in the past to 3 days in the *future*; corrected to always show only the 5 most recent past days plus today.

### Changed
- **Mobile — `pubspec.yaml`:** version bumped `1.1.0+2 → 1.1.1+3`.
- **Client — `package.json`:** version bumped `1.0.0 → 1.1.1`.

---

## [1.1.0] — 2026-07-02

### Added
- **Offline-First Architecture (Web):** Fully decoupled from the ASP.NET Core backend. All prayer logs, Qaza records, and analytics are now stored in `localStorage` via a Pinia store, removing any server dependency for the client SPA.
- **Offline-First Architecture (Mobile):** Fixed `databaseFactory not initialized` crash on web/desktop. Integrated `sqflite_common_ffi` (native) and `sqflite_common_ffi_web` (web/WASM) with platform detection via `kIsWeb`.
- **Onboarding flow (Web + Mobile):** Replaced the JWT-based Login/Register flow with a local onboarding wizard that captures the user's name, preferred language (Bengali/English), and gender. Completion state is persisted locally.
- **Salah time engine (Web + Mobile):** Integrated the `adhan` library for offline, high-precision prayer time calculation and Makruh (forbidden prayer window) detection, based on GPS coordinates from the device.
- **Settings → Reset Application (Web):** A destructive action that clears all `localStorage` keys and re-routes to `/onboarding`.
- **Guide View (Web):** Fiqh reference guide with three tabs: Qaza Rules, Punctuality (Waqt), and App Usage.

### Changed
- **Web — `stores/auth.ts`:** Replaced JWT authentication logic with a local `has_completed_onboarding` flag and user profile persistence.
- **Web — `stores/prayer.ts`:** Migrated from REST API calls to full `localStorage` CRUD, streaks, and analytics computation performed in-browser.
- **Web — Router:** Removed `/login` and `/register` routes; added `/onboarding` with a completion guard.
- **Mobile — Theme:** Hardened dark Material Design 3 palette (`Color(0xFF0F172A)` background, `Color(0xFF5EEAD4)` primary).

### Removed
- **Web — `LoginView.vue`:** Removed the login/register view entirely; superseded by `OnboardingView.vue`.

---

## [1.0.0] — 2026-06-11

### Added
- Initial full-stack platform release.
- **Server (ASP.NET Core 10 / .NET 10):** Clean Architecture with `Iqamah.Domain`, `Iqamah.Application` (CQRS + MediatR), `Iqamah.Infrastructure` (EF Core + PostgreSQL), and `Iqamah.API` (JWT Bearer Auth, REST endpoints).
- **Web Client (Vue 3 + Vite + Tailwind CSS v4):** Dashboard, Qaza ledger, Analytics, and Salah time views. Pinia store with enum normalisation layer for backend enum deserialization.
- **Mobile (Flutter):** Offline SQLite companion with JSON export/import backup, bilingual (Bengali/English) UI, gender-aware Hayd/Nifas logging, Qaza fulfillment state machine.
- **Domain Model:** `PrayerLog` aggregate root, `QazaLog` child entity, domain events (`PrayerMissedDomainEvent`, `QazaFulfilledDomainEvent`), full `PrayerName`, `WaqtStatus`, `MissedReason`, `QazaState` enumerations.
- **Docker / Coolify:** Single-container deployment (Vue SPA served from ASP.NET Core, port 8080).
- **CI/CD:** GitHub Actions pipeline for build + test on push to `main`.
