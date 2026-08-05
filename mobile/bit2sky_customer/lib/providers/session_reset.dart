import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'account_provider.dart';
import 'booking_provider.dart';
import 'cart_provider.dart';
import 'profile_provider.dart';
import 'reports_provider.dart';
import 'subscription_provider.dart';

/// Drops every account-scoped provider so the next read refetches with the
/// current credentials. Must run on BOTH login and logout: cached values from
/// the previous session (wallet balance, cart, addresses, bookings…) would
/// otherwise leak across users until an app restart.
void invalidateSessionProviders(WidgetRef ref) {
  ref.invalidate(meProvider);
  ref.invalidate(healthScoreProvider);
  ref.invalidate(walletProvider);
  ref.invalidate(walletTxnsProvider);
  ref.invalidate(familyProvider);
  ref.invalidate(addressProvider);
  ref.invalidate(cartProvider);
  ref.invalidate(myBookingsProvider);
  ref.invalidate(reportsProvider);
  ref.invalidate(subscriptionProvider);
}
