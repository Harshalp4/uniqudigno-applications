using Bit2sky.Domain.Enums;

namespace Bit2sky.Domain.Entities;

// content.home_sections — dynamic home layout.
public class HomeSection
{
    public Guid Id { get; set; }
    public string Title { get; set; } = null!;
    public HomeSectionType SectionType { get; set; }
    public string? ConfigJson { get; set; }              // section_type-specific config
    public int SortOrder { get; set; }
    public bool IsVisible { get; set; } = true;
    public DateTimeOffset? ValidFrom { get; set; }
    public DateTimeOffset? ValidUntil { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
}

// content.quick_actions — configurable action grid.
public class QuickAction
{
    public Guid Id { get; set; }
    public string Label { get; set; } = null!;
    public string IconUrl { get; set; } = null!;
    public string DeepLink { get; set; } = null!;
    public int SortOrder { get; set; }
    public bool IsVisible { get; set; } = true;
}

// content.nav_items — configurable bottom nav.
public class NavItem
{
    public Guid Id { get; set; }
    public string Label { get; set; } = null!;
    public string IconUrl { get; set; } = null!;
    public string Route { get; set; } = null!;
    public int SortOrder { get; set; }
    public bool IsVisible { get; set; } = true;
}

// content.onboarding_slides — CMS-driven.
public class OnboardingSlide
{
    public Guid Id { get; set; }
    public string Title { get; set; } = null!;
    public string? Subtitle { get; set; }
    public string ImageUrl { get; set; } = null!;
    public int SortOrder { get; set; }
    public bool IsActive { get; set; } = true;
}

// content.banners.
public class Banner
{
    public Guid Id { get; set; }
    public string Title { get; set; } = null!;
    public string? Subtitle { get; set; }                // supporting line on the card
    public string? CtaLabel { get; set; }                // call-to-action button text
    public string ImageUrl { get; set; } = null!;        // SSRF-validated on write
    public string? DeepLink { get; set; }
    public int SortOrder { get; set; }
    public DateTimeOffset? ValidFrom { get; set; }
    public DateTimeOffset? ValidUntil { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTimeOffset CreatedAt { get; set; }
}

// content.articles — CMS (HTML sanitized on write).
public class Article
{
    public Guid Id { get; set; }
    public string Title { get; set; } = null!;
    public string Slug { get; set; } = null!;            // UNIQUE
    public string? Excerpt { get; set; }
    public string Body { get; set; } = null!;            // sanitized HTML
    public string? CoverImageUrl { get; set; }
    public string? Category { get; set; }
    public string Language { get; set; } = "en";          // BCP-47-ish short code
    public bool IsFeatured { get; set; }
    public bool IsPublished { get; set; }
    public int ViewCount { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
}

// content.ai_prompts — versioned AI system prompt (only one active).
public class AiPrompt
{
    public Guid Id { get; set; }
    public string Name { get; set; } = null!;
    public int Version { get; set; }
    public string SystemPrompt { get; set; } = null!;
    public string? Model { get; set; }                   // claude-* model id
    public bool IsActive { get; set; }
    public Guid? CreatedByAdminId { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}
