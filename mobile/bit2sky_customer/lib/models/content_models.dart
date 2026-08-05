/// Dynamic content models from the content.* APIs (DB-driven, zero hardcoding).
library;

import 'dart:convert';

class HomeSection {
  final String id;
  final String title;
  final String sectionType; // banner | categoryGrid | popularTests | ...
  final Map<String, dynamic> config;
  final int sortOrder;

  const HomeSection({
    required this.id,
    required this.title,
    required this.sectionType,
    required this.config,
    required this.sortOrder,
  });

  factory HomeSection.fromJson(Map<String, dynamic> j) => HomeSection(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        sectionType: (j['sectionType'] ?? j['section_type'] ?? '').toString(),
        config: _parseConfig(j['configJson'] ?? j['config_json']),
        sortOrder: (j['sortOrder'] ?? j['sort_order'] ?? 0) as int,
      );

  static Map<String, dynamic> _parseConfig(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    // The API stores section payloads as a JSON string column (ConfigJson).
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        // malformed payload → empty config → the section self-hides
      }
    }
    return const {};
  }
}

class QuickAction {
  final String id;
  final String label;
  final String iconUrl;
  final String deepLink;

  const QuickAction({
    required this.id,
    required this.label,
    required this.iconUrl,
    required this.deepLink,
  });

  factory QuickAction.fromJson(Map<String, dynamic> j) => QuickAction(
        id: (j['id'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
        iconUrl: (j['iconUrl'] ?? j['icon_url'] ?? '').toString(),
        deepLink: (j['deepLink'] ?? j['deep_link'] ?? '/').toString(),
      );
}

class NavItem {
  final String label;
  final String iconUrl;
  final String route;

  const NavItem({required this.label, required this.iconUrl, required this.route});

  factory NavItem.fromJson(Map<String, dynamic> j) => NavItem(
        label: (j['label'] ?? '').toString(),
        iconUrl: (j['iconUrl'] ?? j['icon_url'] ?? '').toString(),
        route: (j['route'] ?? '/').toString(),
      );
}

/// Editorial article (D2 articles rail) — GET /articles, /articles/{slug}.
class Article {
  final String title;
  final String slug;
  final String? excerpt;
  final String? body; // sanitized HTML (detail only)
  final String? coverImageUrl;
  final String? category;
  final String language;
  final bool isFeatured;

  const Article({
    required this.title,
    required this.slug,
    this.excerpt,
    this.body,
    this.coverImageUrl,
    this.category,
    this.language = 'en',
    this.isFeatured = false,
  });

  factory Article.fromJson(Map<String, dynamic> j) => Article(
        title: (j['title'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
        excerpt: j['excerpt']?.toString(),
        body: j['body']?.toString(),
        coverImageUrl: (j['coverImageUrl'] ?? j['cover_image_url'])?.toString(),
        category: j['category']?.toString(),
        language: (j['language'] ?? 'en').toString(),
        isFeatured: j['isFeatured'] == true || j['is_featured'] == true,
      );
}

/// In-app notification (bell) — GET /notifications.
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? deepLink;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.deepLink,
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        body: (j['body'] ?? '').toString(),
        deepLink: (j['deepLink'] ?? j['deep_link'])?.toString(),
        isRead: j['isRead'] == true || j['is_read'] == true,
        createdAt: DateTime.tryParse((j['createdAt'] ?? j['created_at'] ?? '').toString()),
      );
}

/// Home hero banner (Section 8) — carousel slide, DB-driven via /banners.
class HomeBanner {
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final String imageUrl;
  final String deepLink;

  const HomeBanner({
    required this.title,
    this.subtitle,
    this.ctaLabel,
    required this.imageUrl,
    this.deepLink = '/tests',
  });

  factory HomeBanner.fromJson(Map<String, dynamic> j) => HomeBanner(
        title: (j['title'] ?? '').toString(),
        subtitle: j['subtitle']?.toString(),
        ctaLabel: (j['ctaLabel'] ?? j['cta_label'])?.toString(),
        imageUrl: (j['imageUrl'] ?? j['image_url'] ?? '').toString(),
        deepLink: (j['deepLink'] ?? j['deep_link'] ?? '/tests').toString(),
      );
}
