using Bit2sky.Application.Abstractions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Bit2sky.API.Controllers;

[Route("api/v1/cart")]
[Authorize]
public class CartController : ApiControllerBase
{
    private readonly ICartService _cart;

    public CartController(ICartService cart) => _cart = cart;

    [HttpGet]
    public async Task<IActionResult> Get(CancellationToken ct) => Ok(await _cart.GetCartAsync(RequireUserId(), ct));

    [HttpGet("summary")]
    public async Task<IActionResult> Summary(CancellationToken ct) => Ok(await _cart.GetCartAsync(RequireUserId(), ct));

    [HttpPost("items")]
    public async Task<IActionResult> AddItem([FromBody] AddCartItemRequest req, CancellationToken ct)
        => Ok(await _cart.AddItemAsync(RequireUserId(), req, ct), "Item added");

    [HttpDelete("items/{id:guid}")]
    public async Task<IActionResult> RemoveItem(Guid id, CancellationToken ct)
        => Ok(await _cart.RemoveItemAsync(RequireUserId(), id, ct), "Item removed");

    [HttpPost("coupon")]
    public async Task<IActionResult> ApplyCoupon([FromBody] ApplyCouponDto body, CancellationToken ct)
        => Ok(await _cart.ApplyCouponAsync(RequireUserId(), body.Code, ct), "Coupon applied");

    [HttpDelete("coupon")]
    public async Task<IActionResult> RemoveCoupon(CancellationToken ct)
        => Ok(await _cart.RemoveCouponAsync(RequireUserId(), ct), "Coupon removed");

    [HttpPost("wallet-points")]
    public async Task<IActionResult> ApplyWallet([FromBody] WalletPointsDto body, CancellationToken ct)
        => Ok(await _cart.ApplyWalletPointsAsync(RequireUserId(), body.Points, ct), "Wallet points applied");
}

public record WalletPointsDto(decimal Points);
public record ApplyCouponDto(string Code);
