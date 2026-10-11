# Iqamah design system

## Identity and scope

Iqamah is a quiet daily prayer companion for Bangladesh. The existing Vue/Tailwind
application remains authoritative; no second frontend or styling framework is introduced.
Home, timetable, district configuration, Qaza and analytics use the shared foundation.
Some older settings/onboarding utilities still use legacy Tailwind palette and radius classes;
the design consolidation is not claimed to be exhaustive.

## Tokens

`client/src/assets/main.css` owns semantic `--iq-*` tokens and existing `m3-*` compatibility tokens.

| Role | Light | Dark |
| --- | --- | --- |
| Background | `#f7f6f0` | `#111c18` |
| Surface | `#fffefa` | `#1b2923` |
| Secondary surface | `#efeee7` | `#24352c` |
| Text | `#202e27` | `#edf2e9` |
| Secondary text | `#54645b` | `#b0c1b5` |
| Brand / focus | `#16634b` | `#91d5b4` |
| Accent surface | `#e0eee5` | `#204a3b` |
| Border | `#d2d9d0` | `#3c5043` |

Danger, success, warning and informational tokens have paired theme values. Color is not
the only status indicator: timetable and Qaza include explicit text labels.
Spacing is 4/8/12/16/24/32 px. Surfaces use a 16 px radius; controls use 10 px.
Avoid decorative gradients, glass effects, mock phone frames and attention-seeking animation.

## Typography

Noto Sans Bengali regular and bold are copied from the existing mobile assets into the web
bundle, providing offline Bengali and Latin UI text. Body line-height is 1.65; secondary copy
is 14 px with 1.7 line-height. Page headings are 24 px, section headings 18 px, labels and
controls 14 px, navigation 12–14 px, countdown 22 px with tabular numerals.

Arabic prayer names carry `lang="ar"` and use an installed Arabic font fallback; a dedicated
Arabic font is not bundled yet. Arabic glyph availability therefore still needs physical
device testing. Material Symbols Rounded is the existing offline icon family.
Font licensing is recorded in `docs/third-party-notices.md` and embedded font metadata.

## Components and composition

- `.iq-surface`: meaningful grouped content, not a card for every value.
- `.iq-button`: primary action; `.iq-button-secondary`: lower-emphasis action, minimum 44 px.
- `.iq-field`: associated label with input/select; preserve keyboard operation.
- `.iq-link`: visibly underlined navigation or supporting action.
- `AppDialog.vue`: native modal dialog, browser focus containment, Escape and focus restoration.
- `DistrictSelect.vue`: offline bilingual list of all 64 districts.
- `PrayerCalculationSettings.vue`: district/profile and calculation preferences.
- `PrayerTimetable.vue`: shared Home/detail presentation backed by one calculation service.
- Native progress elements include accessible labels and numerical summaries.

## Responsive and accessible behavior

The shell is fluid up to 1120 px, without a simulated phone frame. Bottom navigation is
fixed, includes safe-area padding, and has a matching main-content clearance. Below 480 px
timings become compact aligned rows; larger screens show five columns. At 768 px navigation
uses horizontal icon/label composition. Breakpoints respond to layout needs, not device models.

Focus rings use 3 px semantic outlines with offset. Both themes use a class-based Tailwind
dark variant. Motion and smooth scrolling are disabled under `prefers-reduced-motion`.
The timetable refreshes at one-second intervals and on focus, visibility or native resume;
listeners and its timer are removed on unmount. Do not announce countdown updates through
an assertive live region. Status messages use `role="status"` or `role="alert"` as appropriate.

| Previous motion | Current behavior |
| --- | --- |
| Prayer rows scale on hover/press despite not being controls | Stationary rows with explicit Log/Edit controls |
| Decorative route slides and pulsing celebration | No route or celebration animation in the revised shell/Qaza view |
| No global reduced-motion handling | Animation, transitions and smooth scrolling disabled when reduced motion is requested |
