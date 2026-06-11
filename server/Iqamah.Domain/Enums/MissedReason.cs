namespace Iqamah.Domain.Enums;

/// <summary>
/// The reason a prayer was missed (not offered in its Waqt).
/// Divided into Excused (Ma'dhur) and Unexcused (Ghayr Ma'dhur) categories.
/// This enum drives the Qaza state-machine: only <see cref="ExcusedImpurity"/>
/// suppresses the automatic creation of a Qaza obligation.
/// </summary>
public enum MissedReason
{
    // ── Excused (Ma'dhur) — No sin incurred ────────────────────────────────────

    /// <summary>
    /// Hayd / Nifas (حيض / نفاس) — Ritual impurity due to menstruation or post-natal bleeding.
    /// <br/>No Qaza is required; the prayer obligation is legally lifted for this period.
    /// <br/><b>This is the only reason that does NOT generate a QazaLog.</b>
    /// </summary>
    ExcusedImpurity = 0,

    /// <summary>
    /// Nawm (نوم) — Unintentional sleep that caused the prayer to be missed.
    /// Excused (no sin) but Qaza is still obligatory.
    /// </summary>
    ExcusedSleep = 1,

    /// <summary>
    /// Nisyan (نسيان) — Genuine forgetfulness; no sinful intent.
    /// Excused but Qaza is still obligatory.
    /// </summary>
    ExcusedForgetfulness = 2,

    // ── Unexcused (Ghayr Ma'dhur) — Sin incurred ───────────────────────────────

    /// <summary>
    /// Shughl (شُغل) — Preoccupied with worldly matters / busyness.
    /// Sinful; Qaza is obligatory.
    /// </summary>
    UnexcusedSituational = 3,

    /// <summary>
    /// Kasl (كسل) — Laziness or deliberate neglect.
    /// Major sin; Qaza is obligatory.
    /// </summary>
    UnexcusedLaziness = 4,

    /// <summary>
    /// Ghaflah (غفلة) — Heedlessness / distraction from spiritual duties.
    /// Sinful; Qaza is obligatory.
    /// </summary>
    UnexcusedDistraction = 5
}
