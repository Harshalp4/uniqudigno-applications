using Bit2sky.Application.Abstractions;
using Bit2sky.Application.Authorization;
using Bit2sky.Application.Services;
using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.DependencyInjection;

namespace Bit2sky.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddAutoMapper(cfg => { }, typeof(DependencyInjection).Assembly);
        services.AddValidatorsFromAssembly(typeof(DependencyInjection).Assembly);

        // RBAC + cross-cutting application services.
        services.AddScoped<IPermissionService, PermissionService>();
        services.AddScoped<IOwnershipService, OwnershipService>();
        services.AddScoped<IRateLimitEnforcer, RateLimitService>();
        services.AddSingleton<IInputSanitizationService, InputSanitizationService>();
        services.AddSingleton<IDataMaskingService, DataMaskingService>();

        // Feature services.
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IAdminAuthService, AdminAuthService>();
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<IConfigService, ConfigService>();
        services.AddScoped<ICatalogueService, CatalogueService>();
        services.AddScoped<ICartService, CartService>();
        services.AddScoped<IBookingService, BookingService>();
        services.AddScoped<ISlotService, SlotService>();
        services.AddScoped<IReportService, ReportService>();
        services.AddScoped<IHealthService, HealthService>();
        services.AddScoped<IWalletService, WalletService>();
        services.AddScoped<ISubscriptionService, SubscriptionService>();
        services.AddScoped<IGroupBookingService, GroupBookingService>();
        services.AddScoped<ICouponService, CouponService>();
        services.AddScoped<ICashbackService, CashbackService>();
        services.AddScoped<IRefundService, RefundService>();
        services.AddScoped<IAiCopilotService, AiCopilotService>();
        services.AddScoped<INotificationService, NotificationService>();
        services.AddScoped<ISupportService, SupportService>();
        services.AddScoped<IContentService, ContentService>();
        services.AddScoped<IPartnerService, PartnerService>();
        services.AddScoped<IAdminRbacService, AdminRbacService>();
        services.AddScoped<IAdminAiPromptService, AdminAiPromptService>();
        services.AddScoped<IAdminSupportService, AdminSupportService>();
        services.AddScoped<IAnalyticsService, AnalyticsService>();
        services.AddScoped<ITechnicianService, TechnicianService>();
        services.AddScoped<IRecommendationService, RecommendationService>();

        // Authorization: dynamic permission policies + handler.
        services.AddSingleton<IAuthorizationPolicyProvider, PermissionPolicyProvider>();
        services.AddScoped<IAuthorizationHandler, PermissionAuthorizationHandler>();

        return services;
    }
}
