using Bit2sky.Application.DTOs;
using Bit2sky.Domain.Entities;
using Bit2sky.Shared;

namespace Bit2sky.Application.Abstractions;

public interface IUserService
{
    Task<User> GetMeAsync(Guid userId, CancellationToken ct = default);
    Task<User> UpdateMeAsync(Guid userId, UpdateMeRequest req, CancellationToken ct = default);
    Task<DashboardDto> GetDashboardAsync(Guid userId, CancellationToken ct = default);

    Task<IReadOnlyList<FamilyMember>> GetFamilyAsync(Guid userId, CancellationToken ct = default);
    Task<FamilyMember> AddFamilyAsync(Guid userId, FamilyMemberRequest req, CancellationToken ct = default);
    Task<FamilyMember> UpdateFamilyAsync(Guid userId, Guid id, FamilyMemberRequest req, CancellationToken ct = default);
    Task DeleteFamilyAsync(Guid userId, Guid id, CancellationToken ct = default);

    Task<IReadOnlyList<Address>> GetAddressesAsync(Guid userId, CancellationToken ct = default);
    Task<Address> AddAddressAsync(Guid userId, AddressRequest req, CancellationToken ct = default);
    Task<Address> UpdateAddressAsync(Guid userId, Guid id, AddressRequest req, CancellationToken ct = default);
    Task DeleteAddressAsync(Guid userId, Guid id, CancellationToken ct = default);
    Task SetDefaultAddressAsync(Guid userId, Guid id, CancellationToken ct = default);

    // Admin (PII masked unless caller has users.view_pii).
    Task<PagedResult<object>> AdminListAsync(bool includePii, PageRequest page, CancellationToken ct = default);
    Task DeactivateAsync(Guid userId, bool active, CancellationToken ct = default);
    Task SoftDeleteAsync(Guid userId, CancellationToken ct = default);
}
