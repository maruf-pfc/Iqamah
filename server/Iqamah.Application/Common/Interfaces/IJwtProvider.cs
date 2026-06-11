using Iqamah.Domain.Entities;

namespace Iqamah.Application.Common.Interfaces;

public interface IJwtProvider
{
    string Generate(User user);
}
