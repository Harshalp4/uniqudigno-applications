/// Deep-link validation (Section 4D). Every incoming location is checked against
/// an allowlist of permitted patterns before routing — the app never auto-navigates
/// to an unverified path from an external intent.
class DeepLinkValidator {
  DeepLinkValidator._();

  // Allowlisted route patterns. `:id`/`:slug` segments match a single segment.
  static final List<RegExp> _allowed = [
    r'^/splash$',
    r'^/onboarding$',
    r'^/login$',
    r'^/otp$',
    r'^/auth/setup$',
    r'^/home$',
    r'^/care$',
    r'^/profile$',
    r'^/tests$',
    r'^/blood-tests$',
    r'^/tests/[^/]+$',
    r'^/packages$',
    r'^/packages/custom/builder$',
    r'^/packages/[^/]+$',
    r'^/packages/[^/]+/members$',
    r'^/category/[^/]+$',
    r'^/services/[^/]+$',
    r'^/cart$',
    r'^/booking$',
    r'^/booking/confirm$',
    r'^/reports$',
    r'^/reports/[^/]+$',
    r'^/health$',
    r'^/ai$',
    r'^/wallet$',
    r'^/notifications$',
    r'^/articles$',
    r'^/articles/[^/]+$',
    r'^/prescription$',
    r'^/subscriptions$',
    r'^/orders$',
    r'^/orders/[^/]+$',
    r'^/family$',
    r'^/addresses$',
    r'^/addresses/add$',
    r'^/support$',
    r'^/support/[^/]+$',
    r'^/cashback$',
  ].map(RegExp.new).toList();

  static bool isAllowed(String location) {
    final path = Uri.tryParse(location)?.path ?? location;
    return _allowed.any((re) => re.hasMatch(path));
  }
}
