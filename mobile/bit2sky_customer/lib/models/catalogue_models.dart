/// Catalogue models from /tests and /packages (camelCase JSON from the API).
library;

class Test {
  final String id;
  final String name;
  final String slug;
  final String? shortDescription;
  final num mrp;
  final num price;
  final int parameterCount;
  final String? reportTimeText;
  final bool isPopular;
  final double ratingAverage;

  const Test({
    required this.id,
    required this.name,
    required this.slug,
    this.shortDescription,
    required this.mrp,
    required this.price,
    required this.parameterCount,
    this.reportTimeText,
    this.isPopular = false,
    this.ratingAverage = 0,
  });

  int get discountPercent =>
      mrp <= 0 ? 0 : (((mrp - price) / mrp) * 100).round();

  factory Test.fromJson(Map<String, dynamic> j) => Test(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
        shortDescription: j['shortDescription']?.toString(),
        mrp: (j['mrp'] ?? 0) as num,
        price: (j['price'] ?? 0) as num,
        parameterCount: (j['parameterCount'] ?? 0) as int,
        reportTimeText: j['reportTimeText']?.toString(),
        isPopular: (j['isPopular'] ?? false) as bool,
        ratingAverage: ((j['ratingAverage'] ?? 0) as num).toDouble(),
      );
}

class Package {
  final String id;
  final String name;
  final String slug;
  final String? shortDescription;
  final num mrp;
  final num price;
  final int testCount;
  final int parameterCount;
  final bool isFeatured;
  final bool isPopular;

  /// Category ids this package is tagged with (drives the home filter chips).
  final List<String> categoryIds;

  const Package({
    required this.id,
    required this.name,
    required this.slug,
    this.shortDescription,
    required this.mrp,
    required this.price,
    required this.testCount,
    required this.parameterCount,
    this.isFeatured = false,
    this.isPopular = false,
    this.categoryIds = const [],
  });

  num get saving => mrp - price;
  int get discountPercent =>
      mrp <= 0 ? 0 : (((mrp - price) / mrp) * 100).round();

  factory Package.fromJson(Map<String, dynamic> j) => Package(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
        shortDescription: j['shortDescription']?.toString(),
        mrp: (j['mrp'] ?? 0) as num,
        price: (j['price'] ?? 0) as num,
        testCount: (j['testCount'] ?? 0) as int,
        parameterCount: (j['parameterCount'] ?? 0) as int,
        isFeatured: (j['isFeatured'] ?? false) as bool,
        isPopular: (j['isPopular'] ?? false) as bool,
        categoryIds: ((j['packageCategories'] ?? j['categoryIds'] ?? []) as List)
            .map((e) => e is Map
                ? (e['categoryId'] ?? e['CategoryId'] ?? '').toString()
                : e.toString())
            .where((s) => s.isNotEmpty)
            .toList(),
      );
}

/// One included test line on a package-detail screen.
class PackageTestLine {
  final String name;
  final String slug;
  final int parameterCount;
  const PackageTestLine(
      {required this.name, required this.slug, required this.parameterCount});

  factory PackageTestLine.fromJson(Map<String, dynamic> j) => PackageTestLine(
        name: (j['name'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
        parameterCount: (j['parameterCount'] ?? 0) as int,
      );
}

/// Full package detail (the "Details >>" screen) — GET /packages/{slug}.
class PackageDetail {
  final String id;
  final String name;
  final String slug;
  final String? shortDescription;
  final String? description;
  final num mrp;
  final num price;
  final int testCount;
  final int parameterCount;
  final bool fastingRequired;
  final String? reportTimeText;
  final List<PackageTestLine> includedTests;
  final List<String> categoryIds;
  // Rich detail (all optional; a section hides when its value is empty).
  final int? fastingHours;
  final String? sampleType;
  final String? preparation;
  final String? recommendedFor;
  final List<PackageFaq> faqs;

  const PackageDetail({
    required this.id,
    required this.name,
    required this.slug,
    this.shortDescription,
    this.description,
    required this.mrp,
    required this.price,
    required this.testCount,
    required this.parameterCount,
    this.fastingRequired = false,
    this.reportTimeText,
    this.includedTests = const [],
    this.categoryIds = const [],
    this.fastingHours,
    this.sampleType,
    this.preparation,
    this.recommendedFor,
    this.faqs = const [],
  });

  num get saving => mrp - price;
  int get discountPercent =>
      mrp <= 0 ? 0 : (((mrp - price) / mrp) * 100).round();

  factory PackageDetail.fromJson(Map<String, dynamic> j) => PackageDetail(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
        shortDescription: j['shortDescription']?.toString(),
        description: j['description']?.toString(),
        mrp: (j['mrp'] ?? 0) as num,
        price: (j['price'] ?? 0) as num,
        testCount: (j['testCount'] ?? 0) as int,
        parameterCount: (j['parameterCount'] ?? 0) as int,
        fastingRequired: (j['fastingRequired'] ?? false) as bool,
        reportTimeText: j['reportTimeText']?.toString(),
        includedTests: ((j['includedTests'] ?? []) as List)
            .map((e) => PackageTestLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        categoryIds: ((j['categoryIds'] ?? []) as List)
            .map((e) => e.toString())
            .toList(),
        fastingHours: j['fastingHours'] as int?,
        sampleType: j['sampleType']?.toString(),
        preparation: j['preparation']?.toString(),
        recommendedFor: j['recommendedFor']?.toString(),
        faqs: ((j['faqs'] ?? []) as List)
            .map((e) => PackageFaq.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// One FAQ entry on the package detail screen.
class PackageFaq {
  final String question;
  final String answer;
  const PackageFaq({required this.question, required this.answer});

  factory PackageFaq.fromJson(Map<String, dynamic> j) => PackageFaq(
        question: (j['question'] ?? '').toString(),
        answer: (j['answer'] ?? '').toString(),
      );
}

/// A catalogue category (filter chip) from GET /categories?type=Package.
class CatalogueCategory {
  final String id;
  final String name;
  final String slug;
  final bool showInFilter;

  const CatalogueCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.showInFilter = true,
  });

  factory CatalogueCategory.fromJson(Map<String, dynamic> j) => CatalogueCategory(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
        showInFilter: (j['showInFilter'] ?? true) as bool,
      );
}

class TestParameter {
  final String name;
  final String? unit;
  final String? referenceRange;

  const TestParameter({required this.name, this.unit, this.referenceRange});

  factory TestParameter.fromJson(Map<String, dynamic> j) => TestParameter(
        name: (j['name'] ?? '').toString(),
        unit: j['unit']?.toString(),
        referenceRange: j['referenceRange']?.toString(),
      );
}

/// Category landing page (tap Heart / Diabetes / Women's Care) from
/// GET /browse/{slug} — the category plus its packages (shown first) and tests.
class CategoryLanding {
  final String id;
  final String name;
  final String slug;
  final String type; // Organ / Concern / Persona / Package
  final String? iconUrl;
  final List<Package> packages;
  final List<Test> tests;

  const CategoryLanding({
    required this.id,
    required this.name,
    required this.slug,
    required this.type,
    this.iconUrl,
    this.packages = const [],
    this.tests = const [],
  });

  int get totalCount => packages.length + tests.length;

  factory CategoryLanding.fromJson(Map<String, dynamic> j) => CategoryLanding(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        slug: (j['slug'] ?? '').toString(),
        type: (j['type'] ?? '').toString(),
        iconUrl: j['iconUrl']?.toString(),
        packages: ((j['packages'] ?? []) as List)
            .map((e) => Package.fromJson(e as Map<String, dynamic>))
            .toList(),
        tests: ((j['tests'] ?? []) as List)
            .map((e) => Test.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
