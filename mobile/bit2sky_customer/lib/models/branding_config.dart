/// Branding config from GET /config/branding (DB-driven, zero hardcoding).
class BrandingConfig {
  final String appName;
  final String? tagline;
  final String primaryColor; // #RRGGBB brand primary (CTAs, prices, header)
  final String? secondaryColor; // #RRGGBB sparing accent (logo cyan)
  final String? navAccentColor; // #RRGGBB bottom-nav selection accent
  final String? logoUrl;
  final String? supportPhone; // shown on the "Call to Book" action
  final String? homeCollectionNote; // brand promise on package detail (nullable → hidden)

  /// Accreditation names for the trust block (e.g. NABL, ISO). Empty until the
  /// operator fills `trust_accreditations` — the app hides the row meanwhile.
  final List<String> trustAccreditations;

  /// Operator-entered counters for the trust block (reports / customers /
  /// labs). Values stay verbatim strings; empty entries are hidden.
  final Map<String, String> trustStats;

  const BrandingConfig({
    required this.appName,
    this.tagline,
    required this.primaryColor,
    this.secondaryColor,
    this.navAccentColor,
    this.logoUrl,
    this.supportPhone,
    this.homeCollectionNote,
    this.trustAccreditations = const [],
    this.trustStats = const {},
  });

  // Offline-only fallback (matches the seeded teal); the live app always
  // renders the DB value once /config/branding resolves.
  static const fallback = BrandingConfig(
    appName: 'Unique Diagnostic Centre',
    tagline: 'Your health, our priority',
    primaryColor: '#00A0A8',
  );

  factory BrandingConfig.fromJson(Map<String, dynamic> json) {
    final accreditations = (json['trust_accreditations']?.toString() ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final stats = <String, String>{};
    for (final key in [
      'trust_stat_reports',
      'trust_stat_customers',
      'trust_stat_labs',
    ]) {
      final value = json[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) stats[key] = value;
    }
    return BrandingConfig(
      appName:
          (json['app_name'] ?? json['appName'] ?? 'Unique Diagnostic Centre')
              .toString(),
      tagline: json['app_tagline']?.toString() ?? json['tagline']?.toString(),
      primaryColor:
          (json['primary_color'] ?? json['primaryColor'] ?? '#00A0A8')
              .toString(),
      secondaryColor: (json['secondary_color'] ?? json['secondaryColor'])
          ?.toString(),
      navAccentColor: (json['nav_accent_color'] ?? json['navAccentColor'])
          ?.toString(),
      logoUrl: json['app_logo_url']?.toString() ?? json['logoUrl']?.toString(),
      supportPhone:
          json['support_phone']?.toString() ?? json['supportPhone']?.toString(),
      homeCollectionNote: (json['home_collection_note'] ??
              json['homeCollectionNote'])
          ?.toString(),
      trustAccreditations: accreditations,
      trustStats: stats,
    );
  }
}
