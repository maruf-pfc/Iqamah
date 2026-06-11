namespace Iqamah.Domain.Enums;

/// <summary>
/// Represents the lifecycle state of a Qaza (make-up) prayer obligation.
/// Transitions: <see cref="Pending"/> → <see cref="Offered"/> (terminal; irreversible).
/// </summary>
public enum QazaState
{
    /// <summary>
    /// The make-up prayer has been incurred but not yet performed.
    /// This is the initial state when a <c>QazaLog</c> is created.
    /// </summary>
    Pending = 0,

    /// <summary>
    /// The make-up prayer has been performed. Terminal state.
    /// Captures <c>FulfilledAt</c> and <c>TimeToResolution</c> on transition.
    /// </summary>
    Offered = 1
}
