using FluentAssertions;
using Iqamah.Application.Qazas.Commands;
using Iqamah.Domain.Entities;
using Iqamah.Domain.Enums;
using Iqamah.Domain.Exceptions;
using Iqamah.Domain.Interfaces.Repositories;
using NSubstitute;

namespace Iqamah.Tests.Unit.Application;

public sealed class FulfillQazaCommandHandlerTests
{
    private readonly IQazaLogRepository _qazaLogRepository;
    private readonly FulfillQazaCommandHandler _handler;

    private const int UserId = 12;
    private static readonly DateOnly OriginalDate = new(2025, 5, 5);

    public FulfillQazaCommandHandlerTests()
    {
        _qazaLogRepository = Substitute.For<IQazaLogRepository>();
        _handler = new FulfillQazaCommandHandler(_qazaLogRepository);
    }

    [Fact]
    public async Task Handle_PendingQaza_TransitionsToOfferedAndSaves()
    {
        // Arrange
        var qazaId = Guid.NewGuid();
        var qaza = QazaLog.CreatePending(Guid.NewGuid(), UserId, PrayerName.Maghrib, OriginalDate);

        _qazaLogRepository.GetByIdAsync(qazaId, Arg.Any<CancellationToken>())
            .Returns(qaza);

        var command = new FulfillQazaCommand(qazaId, UserId);

        // Act
        await _handler.Handle(command, CancellationToken.None);

        // Assert
        qaza.State.Should().Be(QazaState.Offered);
        qaza.IsFulfilled.Should().BeTrue();
        await _qazaLogRepository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Handle_NonExistentQaza_ThrowsKeyNotFoundException()
    {
        // Arrange
        var qazaId = Guid.NewGuid();
        _qazaLogRepository.GetByIdAsync(qazaId, Arg.Any<CancellationToken>())
            .Returns((QazaLog?)null);

        var command = new FulfillQazaCommand(qazaId, UserId);

        // Act
        var act = () => _handler.Handle(command, CancellationToken.None);

        // Assert
        await act.Should().ThrowAsync<KeyNotFoundException>();
        await _qazaLogRepository.Received(0).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Handle_UnauthorizedUser_ThrowsUnauthorizedAccessException()
    {
        // Arrange
        var qazaId = Guid.NewGuid();
        var qaza = QazaLog.CreatePending(Guid.NewGuid(), UserId, PrayerName.Maghrib, OriginalDate);

        _qazaLogRepository.GetByIdAsync(qazaId, Arg.Any<CancellationToken>())
            .Returns(qaza);

        var command = new FulfillQazaCommand(qazaId, 999); // Different user id

        // Act
        var act = () => _handler.Handle(command, CancellationToken.None);

        // Assert
        await act.Should().ThrowAsync<UnauthorizedAccessException>();
        qaza.State.Should().Be(QazaState.Pending);
        await _qazaLogRepository.Received(0).SaveChangesAsync(Arg.Any<CancellationToken>());
    }
}
