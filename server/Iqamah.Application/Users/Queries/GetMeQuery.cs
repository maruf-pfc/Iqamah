using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Iqamah.Domain.Interfaces.Repositories;
using MediatR;

namespace Iqamah.Application.Users.Queries;

public sealed record GetMeQuery(int UserId) : IRequest<UserResponse>;

public sealed record UserResponse(int Id, string Username, string Email);

public sealed class GetMeQueryHandler : IRequestHandler<GetMeQuery, UserResponse>
{
    private readonly IUserRepository _userRepository;

    public GetMeQueryHandler(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }

    public async Task<UserResponse> Handle(GetMeQuery request, CancellationToken cancellationToken)
    {
        var user = await _userRepository.GetByIdAsync(request.UserId, cancellationToken);

        if (user == null)
        {
            throw new KeyNotFoundException("User not found.");
        }

        return new UserResponse(user.Id, user.Username, user.Email);
    }
}
