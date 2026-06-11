namespace Iqamah.Domain.Exceptions;

/// <summary>
/// Thrown when a business-rule invariant inside the Domain is violated.
/// Caught by global middleware and mapped to HTTP 422 Unprocessable Entity.
/// </summary>
public sealed class DomainException : Exception
{
    public DomainException(string message) : base(message) { }

    public DomainException(string message, Exception inner) : base(message, inner) { }
}
