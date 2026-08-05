import 'package:go_router/go_router.dart';

import '../features/account/add_address_screen.dart';
import '../features/account/addresses_screen.dart';
import '../features/articles/articles_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/services/prescription_stub_screen.dart';
import '../features/account/family_screen.dart';
import '../features/account/my_orders_screen.dart';
import '../features/account/subscriptions_screen.dart';
import '../features/account/support_screen.dart';
import '../features/account/ticket_detail_screen.dart';
import '../features/account/wallet_screen.dart';
import '../features/ai/ai_copilot_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/cashback/cashback_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/profile_setup_screen.dart';
import '../features/booking/booking_screen.dart';
import '../features/booking/confirmation_screen.dart';
import '../features/booking/order_detail_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/catalogue/blood_tests_landing_screen.dart';
import '../features/catalogue/catalogue_screen.dart';
import '../features/catalogue/select_members_screen.dart';
import '../features/catalogue/custom_package_builder_screen.dart';
import '../features/catalogue/test_detail_screen.dart';
import '../features/catalogue/package_detail_screen.dart';
import '../features/catalogue/category_landing_screen.dart';
import '../features/catalogue/all_tests_screen.dart';
import '../features/catalogue/packages_screen.dart';
import '../features/reports/report_detail_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/services/service_landing_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/splash/splash_screen.dart';
import 'deep_link_validator.dart';

/// GoRouter (Section 8). Every incoming location is validated against the
/// deep-link allowlist before routing (Section 4D).
final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) =>
      DeepLinkValidator.isAllowed(state.uri.path) ? null : '/home',
  errorBuilder: (_, _) => const AppShell(initialRoute: '/home'),
  routes: [
    GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/cashback', builder: (_, _) => const CashbackScreen()),
    GoRoute(path: '/otp', builder: (_, _) => const OtpScreen()),
    GoRoute(path: '/auth/setup', builder: (_, _) => const ProfileSetupScreen()),
    GoRoute(
      path: '/home',
      builder: (_, _) => const AppShell(initialRoute: '/home'),
    ),
    GoRoute(
      path: '/care',
      builder: (_, _) => const AppShell(initialRoute: '/care'),
    ),
    // Standalone page (not a nav tab): routing it through AppShell would
    // fall back to the Home tab when '/reports' isn't in the bottom nav.
    GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
    GoRoute(
      path: '/health',
      builder: (_, _) => const AppShell(initialRoute: '/health'),
    ),
    GoRoute(
      path: '/profile',
      builder: (_, _) => const AppShell(initialRoute: '/profile'),
    ),
    GoRoute(path: '/tests', builder: (_, _) => const CatalogueScreen()),
    GoRoute(
        path: '/blood-tests',
        builder: (_, _) => const BloodTestsLandingScreen()),
    GoRoute(
        path: '/packages/:slug/members',
        builder: (_, state) => SelectMembersScreen(
            slug: state.pathParameters['slug'] ?? '')),
    GoRoute(path: '/packages', builder: (_, _) => const PackagesScreen()),
    GoRoute(
      path: '/services/:id',
      builder: (_, s) =>
          ServiceLandingScreen(serviceId: s.pathParameters['id']!),
    ),
    GoRoute(path: '/tests/all', builder: (_, _) => const AllTestsScreen()),
    GoRoute(
      path: '/tests/:slug',
      builder: (_, s) => TestDetailScreen(slug: s.pathParameters['slug']!),
    ),
    GoRoute(
      path: '/reports/:id',
      builder: (_, s) => ReportDetailScreen(reportId: s.pathParameters['id']!),
    ),
    GoRoute(
      path: '/packages/custom/builder',
      builder: (_, _) => const CustomPackageBuilderScreen(),
    ),
    GoRoute(
      path: '/packages/:slug',
      builder: (_, st) => PackageDetailScreen(slug: st.pathParameters['slug']!),
    ),
    GoRoute(
      path: '/category/:slug',
      builder: (_, st) =>
          CategoryLandingScreen(slug: st.pathParameters['slug']!),
    ),
    GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
    GoRoute(path: '/ai', builder: (_, _) => const AiCopilotScreen()),
    GoRoute(path: '/wallet', builder: (_, _) => const WalletScreen()),
    GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
    GoRoute(path: '/articles', builder: (_, _) => const ArticlesScreen()),
    GoRoute(
        path: '/articles/:slug',
        builder: (_, s) => ArticleDetailScreen(slug: s.pathParameters['slug']!)),
    GoRoute(path: '/prescription', builder: (_, _) => const PrescriptionStubScreen()),
    GoRoute(
      path: '/subscriptions',
      builder: (_, _) => const SubscriptionsScreen(),
    ),
    GoRoute(path: '/orders', builder: (_, _) => const MyOrdersScreen()),
    GoRoute(
        path: '/orders/:id',
        builder: (_, s) => OrderDetailScreen(bookingId: s.pathParameters['id']!)),
    GoRoute(path: '/family', builder: (_, _) => const FamilyScreen()),
    GoRoute(path: '/addresses', builder: (_, _) => const AddressesScreen()),
    GoRoute(path: '/addresses/add', builder: (_, _) => const AddAddressScreen()),
    GoRoute(path: '/support', builder: (_, _) => const SupportScreen()),
    GoRoute(
      path: '/support/:id',
      builder: (_, s) => TicketDetailScreen(ticketId: s.pathParameters['id']!),
    ),
    GoRoute(path: '/booking', builder: (_, _) => const BookingScreen()),
    GoRoute(
      path: '/booking/confirm',
      builder: (_, s) =>
          ConfirmationScreen(paid: s.uri.queryParameters['paid'] == '1'),
    ),
  ],
);
