using Bit2sky.Application.Abstractions;
using Bit2sky.Application.Authorization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Bit2sky.API.Controllers;

[Route("api/v1/wallet")]
[Authorize]
public class WalletController : ApiControllerBase
{
    private readonly IWalletService _wallet;
    public WalletController(IWalletService wallet) => _wallet = wallet;

    [HttpGet] public async Task<IActionResult> Get(CancellationToken ct) => Ok(await _wallet.GetWalletAsync(RequireUserId(), ct));
    [HttpGet("transactions")] public async Task<IActionResult> Transactions(CancellationToken ct) => Ok(await _wallet.GetTransactionsAsync(RequireUserId(), ct));
    [HttpGet("tier-benefits"), AllowAnonymous] public async Task<IActionResult> Tiers(CancellationToken ct) => Ok(await _wallet.GetTierBenefitsAsync(ct));
    [HttpPost("redeem")] public async Task<IActionResult> Redeem([FromBody] RedeemDto body, CancellationToken ct) => Ok(await _wallet.RedeemAsync(RequireUserId(), body.Amount, ct), "Redeemed");
}

[Route("api/v1/admin/wallet")]
[Authorize]
public class AdminWalletController : ApiControllerBase
{
    private readonly IWalletService _wallet;
    public AdminWalletController(IWalletService wallet) => _wallet = wallet;

    [HttpPut("{userId:guid}/adjust")]
    [RequirePermission("wallet.adjust")]
    public async Task<IActionResult> Adjust(Guid userId, [FromBody] AdjustDto body, CancellationToken ct)
    {
        await _wallet.AdminAdjustAsync(userId, body.Amount, body.Reason, RequireUserId(), ct);
        return Ok<object?>(null, "Wallet adjusted");
    }
}

[Route("api/v1/subscriptions")]
[Authorize]
public class SubscriptionController : ApiControllerBase
{
    private readonly ISubscriptionService _subs;
    public SubscriptionController(ISubscriptionService subs) => _subs = subs;

    [HttpGet] public async Task<IActionResult> List(CancellationToken ct) => Ok(await _subs.ListAsync(RequireUserId(), ct));
    [HttpPost] public async Task<IActionResult> Create([FromBody] SubscriptionRequest req, CancellationToken ct) => Ok(await _subs.CreateAsync(RequireUserId(), req, ct), "Created");
    [HttpPut("{id:guid}/pause")] public async Task<IActionResult> Pause(Guid id, [FromBody] PauseDto body, CancellationToken ct) { await _subs.PauseAsync(RequireUserId(), id, body.Until, ct); return Ok<object?>(null, "Paused"); }
    [HttpPut("{id:guid}/resume")] public async Task<IActionResult> Resume(Guid id, CancellationToken ct) { await _subs.ResumeAsync(RequireUserId(), id, ct); return Ok<object?>(null, "Resumed"); }
    [HttpDelete("{id:guid}")] public async Task<IActionResult> Cancel(Guid id, CancellationToken ct) { await _subs.CancelAsync(RequireUserId(), id, ct); return Ok<object?>(null, "Cancelled"); }
}

[Route("api/v1/group-bookings")]
public class GroupBookingController : ApiControllerBase
{
    private readonly IGroupBookingService _groups;
    public GroupBookingController(IGroupBookingService groups) => _groups = groups;

    [HttpPost, Authorize] public async Task<IActionResult> Create([FromBody] GroupBookingRequest req, CancellationToken ct) => Ok(await _groups.CreateAsync(RequireUserId(), req, ct), "Created");
    [HttpGet("{code}"), AllowAnonymous] public async Task<IActionResult> Get(string code, CancellationToken ct) => Ok(await _groups.GetByCodeAsync(code, ct));
    [HttpPost("{code}/join"), Authorize] public async Task<IActionResult> Join(string code, CancellationToken ct) { await _groups.JoinAsync(RequireUserId(), code, ct); return Ok<object?>(null, "Joined"); }
    [HttpGet("my-groups"), Authorize] public async Task<IActionResult> Mine(CancellationToken ct) => Ok(await _groups.MyGroupsAsync(RequireUserId(), ct));
    [HttpDelete("{id:guid}/leave"), Authorize] public async Task<IActionResult> Leave(Guid id, CancellationToken ct) { await _groups.LeaveAsync(RequireUserId(), id, ct); return Ok<object?>(null, "Left"); }
}

[Route("api/v1")]
[Authorize]
public class CouponCashbackController : ApiControllerBase
{
    private readonly ICouponService _coupons;
    private readonly ICashbackService _cashback;
    public CouponCashbackController(ICouponService coupons, ICashbackService cashback)
    { _coupons = coupons; _cashback = cashback; }

    [HttpGet("coupons"), Microsoft.AspNetCore.Authorization.AllowAnonymous]
    public async Task<IActionResult> Available(CancellationToken ct)
    {
        var now = DateTimeOffset.UtcNow;
        var all = await _coupons.ListAsync(ct);
        var live = all.Where(c => c.IsActive
                && (c.ValidFrom is null || c.ValidFrom <= now)
                && (c.ValidUntil is null || c.ValidUntil >= now)
                && (c.TotalUsageLimit is null || c.UsedCount < c.TotalUsageLimit))
            .OrderBy(c => c.MinOrderValue ?? 0)
            .Select(c => new
            {
                c.Code, c.Description,
                Type = c.Type.ToString(), c.Value, c.MaxDiscount, c.MinOrderValue,
            });
        return Ok(live);
    }

    [HttpPost("coupons/validate")]
    public async Task<IActionResult> Validate([FromBody] ValidateCouponDto body, CancellationToken ct)
        => Ok(await _coupons.ValidateAsync(RequireUserId(), body.Code, body.OrderValue, ct));

    [HttpGet("cashback/active-offers"), AllowAnonymous]
    public async Task<IActionResult> ActiveOffers(CancellationToken ct) => Ok(await _cashback.GetActiveOffersAsync(ct));
}

public record RedeemDto(decimal Amount);
public record AdjustDto(decimal Amount, string Reason);
public record PauseDto(DateOnly? Until);
public record ValidateCouponDto(string Code, decimal OrderValue);

// Admin coupon management (Section 11) — gated per action.
[Route("api/v1/admin/coupons")]
[Authorize]
public class AdminCouponController : ApiControllerBase
{
    private readonly ICouponService _coupons;
    public AdminCouponController(ICouponService coupons) => _coupons = coupons;

    [HttpGet, RequirePermission("coupons.view")]
    public async Task<IActionResult> List(CancellationToken ct) => Ok(await _coupons.ListAsync(ct));

    [HttpPost, RequirePermission("coupons.create")]
    public async Task<IActionResult> Create([FromBody] CouponInput body, CancellationToken ct)
        => Ok(await _coupons.CreateAsync(body, ct), "Coupon created");

    [HttpPut("{id:guid}"), RequirePermission("coupons.update")]
    public async Task<IActionResult> Update(Guid id, [FromBody] CouponInput body, CancellationToken ct)
        => Ok(await _coupons.UpdateAsync(id, body, ct), "Coupon updated");

    [HttpDelete("{id:guid}"), RequirePermission("coupons.delete")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    { await _coupons.DeleteAsync(id, ct); return Ok<object?>(null, "Coupon deleted"); }
}

// Admin refund queue (Section 11) — view + process/reject, gated per action.
[Route("api/v1/admin/refunds")]
[Authorize]
public class AdminRefundController : ApiControllerBase
{
    private readonly IRefundService _refunds;
    public AdminRefundController(IRefundService refunds) => _refunds = refunds;

    [HttpGet, RequirePermission("refunds.view")]
    public async Task<IActionResult> List([FromQuery] string? status, CancellationToken ct)
        => Ok(await _refunds.ListAsync(status, ct));

    [HttpPut("{id:guid}/process"), RequirePermission("refunds.process")]
    public async Task<IActionResult> Process(Guid id, CancellationToken ct)
    { await _refunds.ProcessAsync(id, RequireUserId(), ct); return Ok<object?>(null, "Refund processed"); }

    [HttpPut("{id:guid}/reject"), RequirePermission("refunds.process")]
    public async Task<IActionResult> Reject(Guid id, [FromBody] RejectRefundDto body, CancellationToken ct)
    { await _refunds.RejectAsync(id, RequireUserId(), body.Reason, ct); return Ok<object?>(null, "Refund rejected"); }
}

public record RejectRefundDto(string? Reason);
