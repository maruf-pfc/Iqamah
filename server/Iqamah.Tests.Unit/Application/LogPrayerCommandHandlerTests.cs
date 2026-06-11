using FluentAssertions;
using Iqamah.Application.Prayers.Commands;
using Iqamah.Domain.Entities;
using Iqamah.Domain.Enums;
using Iqamah.Domain.Exceptions;
using Iqamah.Domain.Interfaces.Repositories;
using NSubstitute;

namespace Iqamah.Tests.Unit.Application;

public sealed class LogPrayerCommandHandlerTests
{
    private readonly IPrayerLogRepository _prayerLogRepository;
    private readonly IQazaLogRepository _qazaLogRepository;
    private readonly LogPrayerCommandHandler _handler;

    private static readonly DateOnly Today = DateOnly.FromDateTime(DateTime.UtcNow);
    private const int UserId = 10;

    public LogPrayerCommandHandlerTests()
    {
        _prayerLogRepository = Substitute.For<IPrayerLogRepository>();
        _qazaLogRepository = Substitute.For<IQazaLogRepository>();
        _handler = new LogPrayerCommandHandler(_prayerLogRepository, _qazaLogRepository);
    }

    [Fact]
    public async Task Handle_NewOfferedPrayer_CreatesAndSavesLog()
    {
        // Arrange
        var command = new LogPrayerCommand(
            UserId, PrayerName.Fajr, Today,
            IsOffered: true, WaqtStatus: WaqtStatus.AwwalAlWaqt);

        _prayerLogRepository.GetByUserDateAndPrayerAsync(UserId, Today, PrayerName.Fajr)
            .Returns((PrayerLog?)null);

        // Act
        var result = await _handler.Handle(command, CancellationToken.None);

        // Assert
        result.Should().NotBeEmpty();
        await _prayerLogRepository.Received(1).AddAsync(Arg.Any<PrayerLog>(), Arg.Any<CancellationToken>());
        await _prayerLogRepository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Handle_NewMissedPrayer_CreatesAndSavesLog()
    {
        // Arrange
        var command = new LogPrayerCommand(
            UserId, PrayerName.Fajr, Today,
            IsOffered: false, MissedReason: MissedReason.UnexcusedLaziness);

        _prayerLogRepository.GetByUserDateAndPrayerAsync(UserId, Today, PrayerName.Fajr)
            .Returns((PrayerLog?)null);

        // Act
        var result = await _handler.Handle(command, CancellationToken.None);

        // Assert
        result.Should().NotBeEmpty();
        await _prayerLogRepository.Received(1).AddAsync(Arg.Is<PrayerLog>(p => p.RequiresQaza() == true), Arg.Any<CancellationToken>());
        await _prayerLogRepository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Handle_ExistingPrayer_UpdatesAndSavesLog()
    {
        // Arrange
        var existingLog = PrayerLog.Create(UserId, PrayerName.Fajr, Today,
            isOffered: true, waqtStatus: WaqtStatus.WastAlWaqt);

        var command = new LogPrayerCommand(
            UserId, PrayerName.Fajr, Today,
            IsOffered: true, WaqtStatus: WaqtStatus.AwwalAlWaqt, IsJamaah: true);

        _prayerLogRepository.GetByUserDateAndPrayerAsync(UserId, Today, PrayerName.Fajr)
            .Returns(existingLog);

        // Act
        var result = await _handler.Handle(command, CancellationToken.None);

        // Assert
        result.Should().Be(existingLog.Id);
        existingLog.WaqtStatus.Should().Be(WaqtStatus.AwwalAlWaqt);
        existingLog.IsJamaah.Should().BeTrue();
        await _prayerLogRepository.Received(0).AddAsync(Arg.Any<PrayerLog>(), Arg.Any<CancellationToken>());
        await _prayerLogRepository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Handle_Correction_FromMissedToOffered_DeletesPendingQaza()
    {
        // Arrange
        var existingLog = PrayerLog.Create(UserId, PrayerName.Fajr, Today,
            isOffered: false, missedReason: MissedReason.UnexcusedLaziness);

        var qazaLog = QazaLog.CreatePending(existingLog.Id, UserId, PrayerName.Fajr, Today);
        existingLog.AttachQazaLog(qazaLog);

        var command = new LogPrayerCommand(
            UserId, PrayerName.Fajr, Today,
            IsOffered: true, WaqtStatus: WaqtStatus.AwwalAlWaqt);

        _prayerLogRepository.GetByUserDateAndPrayerAsync(UserId, Today, PrayerName.Fajr)
            .Returns(existingLog);

        // Act
        await _handler.Handle(command, CancellationToken.None);

        // Assert
        _qazaLogRepository.Received(1).Delete(qazaLog);
        await _prayerLogRepository.Received(1).SaveChangesAsync(Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Handle_Correction_FromMissedToOffered_WhenQazaIsAlreadyFulfilled_ThrowsDomainException()
    {
        // Arrange
        var existingLog = PrayerLog.Create(UserId, PrayerName.Fajr, Today,
            isOffered: false, missedReason: MissedReason.UnexcusedLaziness);

        var qazaLog = QazaLog.CreatePending(existingLog.Id, UserId, PrayerName.Fajr, Today);
        qazaLog.Fulfill(); // Fulfill it so it's resolved
        existingLog.AttachQazaLog(qazaLog);

        var command = new LogPrayerCommand(
            UserId, PrayerName.Fajr, Today,
            IsOffered: true, WaqtStatus: WaqtStatus.AwwalAlWaqt);

        _prayerLogRepository.GetByUserDateAndPrayerAsync(UserId, Today, PrayerName.Fajr)
            .Returns(existingLog);

        // Act
        var act = () => _handler.Handle(command, CancellationToken.None);

        // Assert
        await act.Should().ThrowAsync<DomainException>()
            .WithMessage("*already been fulfilled*");
        _qazaLogRepository.Received(0).Delete(Arg.Any<QazaLog>());
    }
}
