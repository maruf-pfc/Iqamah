using FluentValidation;
using Iqamah.Domain.Exceptions;
using Iqamah.Domain.Interfaces.Repositories;
using MediatR;

namespace Iqamah.Application.Qazas.Commands;

public sealed record FulfillQazaCommand(Guid QazaLogId, int UserId) : IRequest<Unit>;

public sealed class FulfillQazaCommandValidator : AbstractValidator<FulfillQazaCommand>
{
    public FulfillQazaCommandValidator()
    {
        RuleFor(x => x.QazaLogId)
            .NotEmpty().WithMessage("QazaLogId is required.");

        RuleFor(x => x.UserId)
            .GreaterThan(0).WithMessage("UserId must be greater than 0.");
    }
}

public sealed class FulfillQazaCommandHandler : IRequestHandler<FulfillQazaCommand, Unit>
{
    private readonly IQazaLogRepository _qazaLogRepository;

    public FulfillQazaCommandHandler(IQazaLogRepository qazaLogRepository)
    {
        _qazaLogRepository = qazaLogRepository;
    }

    public async Task<Unit> Handle(FulfillQazaCommand request, CancellationToken cancellationToken)
    {
        var qaza = await _qazaLogRepository.GetByIdAsync(request.QazaLogId, cancellationToken);

        if (qaza == null)
        {
            throw new KeyNotFoundException($"QazaLog with ID {request.QazaLogId} was not found.");
        }

        if (qaza.UserId != request.UserId)
        {
            throw new UnauthorizedAccessException("You do not have permission to fulfill this Qaza obligation.");
        }

        qaza.Fulfill();

        await _qazaLogRepository.SaveChangesAsync(cancellationToken);

        return Unit.Value;
    }
}
