/// Branding config from GET /config/branding (DB-driven, zero hardcoding).
class BrandingConfig {
  final String appName;
  final String? tagline;
  final String primaryColor; // #RRGGBB
  final String? logoUrl;

  const BrandingConfig({
    required this.appName,
    this.tagline,
    required this.primaryColor,
    this.logoUrl,
  });

  static const fallback = BrandingConfig(
    appName: 'VitalScan',
    tagline: 'Health, decoded.',
    primaryColor: '#00897B',
  );

  factory BrandingConfig.fromJson(Map<String, dynamic> json) => BrandingConfig(
        appName: (json['app_name'] ?? json['appName'] ?? 'VitalScan').toString(),
        tagline: json['app_tagline']?.toString() ?? json['tagline']?.toString(),
        primaryColor:
            (json['primary_color'] ?? json['primaryColor'] ?? '#00897B').toString(),
        logoUrl: json['app_logo_url']?.toString() ?? json['logoUrl']?.toString(),
      );
}
