import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/brand_palette.dart';
import '../../models/cart_models.dart';
import '../../models/account_models.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/brand_palette_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/profile_provider.dart';
import '../catalogue/select_members_screen.dart';
import '../../widgets/buttons.dart';
import '../../widgets/pressable.dart';
import '../auth/login_sheet.dart';

/// Checkout (combined wireframe A+B+C+D): cream canvas, progress stepper,
/// pay-first gradient hero, coupon chips + "view all" sheet, an itemised
/// receipt ticket (coupon as a dashed green tag), wallet toggle, trust row,
/// and a swipe-to-book slider. All ambient motion honours reduce-motion.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen>
    with SingleTickerProviderStateMixin {
  static const _canvas = Color(0xFFFAF3EA);

  /// Drives the hero sheen + savings shimmer.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );

  @override
  void initState() {
    super.initState();
    // The "added to cart" snackbar must not follow the user into checkout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _ambient.stop();
    } else if (!_ambient.isAnimating) {
      _ambient.repeat();
    }
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon(String code) async {
    final loggedIn =
        ref.read(authProvider).status == AuthStatus.authenticated;
    if (!loggedIn) {
      final ok = await showLoginSheet(context);
      if (!ok || !mounted) return;
      await ref.read(cartProvider.notifier).mergeGuestCartToServer();
    }
    final err = await ref.read(cartProvider.notifier).applyCoupon(code);
    if (!mounted || err == null) return; // success is visible in the UI itself
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(err)));
  }

  void _openCouponSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _CouponSheet(onApply: (code) {
        Navigator.of(context).pop();
        _applyCoupon(code);
      }),
    );
  }

  Future<void> _reassign(CartItem item) async {
    final pick = await showMemberSheet(context, ref);
    if (pick == null || !mounted) return;
    final notifier = ref.read(cartProvider.notifier);
    await notifier.removeItem(item.id);
    if (item.packageId != null) {
      await notifier.addPackage(
          id: item.packageId!,
          name: item.itemName,
          mrp: item.mrp,
          price: item.price,
          familyMemberId: pick.memberId);
    } else if (item.testId != null) {
      await notifier.addTest(
          id: item.testId!,
          name: item.itemName,
          mrp: item.mrp,
          price: item.price,
          familyMemberId: pick.memberId);
    }
  }

  Future<void> _checkout() async {
    final loggedIn =
        ref.read(authProvider).status == AuthStatus.authenticated;
    if (!loggedIn) {
      final ok = await showLoginSheet(context);
      if (!ok || !mounted) return;
    }
    if (mounted) context.push('/booking');
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final palette = ref.watch(brandPaletteProvider);

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        bottom: false,
        child: cart.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _Message(text: e.toString()),
          data: (c) {
            if (c == null) {
              return const _Message(text: 'Please log in to view your cart.');
            }
            return Column(
              children: [
                _TopBar(onBack: () =>
                    context.canPop() ? context.pop() : context.go('/home')),
                if (c.isEmpty)
                  const Expanded(child: _EmptyCart())
                else ...[
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 12),
                      children: [
                        const _Stepper(),
                        _PayHero(cart: c, ambient: _ambient),
                        if (c.couponCode != null)
                          _SavedStrip(cart: c, ambient: _ambient),
                        _CouponChips(
                          cart: c,
                          onApply: _applyCoupon,
                          onEnterCode: _openCouponSheet,
                        ),
                        _ReceiptTicket(
                          cart: c,
                          palette: palette,
                          onRemoveCoupon: () =>
                              ref.read(cartProvider.notifier).removeCoupon(),
                          onRemoveItem: (id) =>
                              ref.read(cartProvider.notifier).removeItem(id),
                          onViewCoupons: _openCouponSheet,
                          onReassign: _reassign,
                        ),
                        const _WalletCard(),
                        const _TrustRow(),
                      ],
                    ),
                  ),
                  _SwipeToBook(
                    amount: c.payable,
                    onComplete: _checkout,
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s4, AppSpacing.s4, AppSpacing.s4, 0),
      child: Row(children: [
        IconButton(
            onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded)),
        Expanded(
          child: Text('My Cart',
              textAlign: TextAlign.center,
              style: AppTextStyles.h2
                  .copyWith(fontSize: 17, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 48),
      ]),
    );
  }
}

/// A → progress stepper: Cart (now) · Slot · Pay.
class _Stepper extends StatelessWidget {
  const _Stepper();

  @override
  Widget build(BuildContext context) {
    const steps = [('Cart', 1), ('Slot', 0), ('Pay', 0)];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s4, AppSpacing.s16, AppSpacing.s12),
      child: Row(
        children: [
          for (final (i, s) in steps.indexed) ...[
            if (i > 0)
              Expanded(
                child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 14),
                    color: const Color(0xFFE7DFD2)),
              ),
            Column(children: [
              Container(
                width: 21,
                height: 21,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: s.$2 == 2
                      ? const Color(0xFF36B665)
                      : s.$2 == 1
                          ? const Color(0xFF428AC7)
                          : const Color(0xFFE7DFD2),
                ),
                child: s.$2 == 2
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : Text('${i + 1}',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: s.$2 == 1
                                ? Colors.white
                                : const Color(0xFF8A8272))),
              ),
              const SizedBox(height: 3),
              Text(s.$1,
                  style: AppTextStyles.caption.copyWith(
                      fontSize: 9.5, color: AppColors.textSecondary)),
            ]),
          ],
        ],
      ),
    );
  }
}

/// C → pay-first gradient hero with total savings badge + sheen.
class _PayHero extends ConsumerWidget {
  final CartSummary cart;
  final Animation<double> ambient;
  const _PayHero({required this.cart, required this.ambient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(brandPaletteProvider);
    final mrpTotal = cart.itemsTotal + cart.discount;
    final savings = cart.discount +
        cart.couponDiscount +
        cart.groupDiscount +
        cart.walletApplied;
    final pct = mrpTotal <= 0 ? 0 : ((savings / mrpTotal) * 100).round();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.r20),
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [palette.primary, palette.primaryDark]),
      ),
      child: Stack(children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: ambient,
            builder: (context, _) {
              final t = Curves.easeInOut
                  .transform((ambient.value / 0.4).clamp(0.0, 1.0));
              if (t <= 0 || t >= 1) return const SizedBox.shrink();
              return FractionalTranslation(
                translation: Offset(-1.2 + 2.4 * t, 0),
                child: Transform.rotate(
                  angle: 0.3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.18),
                        Colors.white.withValues(alpha: 0),
                      ]),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('To pay',
                style: AppTextStyles.caption
                    .copyWith(color: Colors.white70, fontSize: 10.5)),
            const SizedBox(height: 2),
            Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('₹${cart.payable}',
                      style: AppTextStyles.h1.copyWith(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  if (mrpTotal > cart.payable)
                    Text('₹$mrpTotal',
                        style: AppTextStyles.body.copyWith(
                            color: Colors.white70,
                            fontSize: 13,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.white70)),
                ]),
            if (savings > 0) ...[
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.r100),
                ),
                child: Text('🎉 Saving ₹$savings ($pct%)',
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

/// B → shimmering "coupon working" strip.
class _SavedStrip extends StatelessWidget {
  final CartSummary cart;
  final Animation<double> ambient;
  const _SavedStrip({required this.cart, required this.ambient});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambient,
      builder: (context, _) => Container(
        margin: const EdgeInsets.fromLTRB(
            AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, 0),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          gradient: LinearGradient(
            begin: Alignment(-1 + 2 * ambient.value, 0),
            end: Alignment(2 * ambient.value, 0),
            colors: const [
              Color(0xFFDFF3E7),
              Color(0xFFC4E8D2),
              Color(0xFFDFF3E7)
            ],
          ),
        ),
        child: Text(
            '🏷️ ${cart.couponCode} applied — instant ₹${cart.couponDiscount} off',
            style: AppTextStyles.captionMed.copyWith(
                color: const Color(0xFF1F7A43), fontWeight: FontWeight.w800)),
      ),
    );
  }
}

/// C → one-tap coupon chips + "enter code".
class _CouponChips extends ConsumerWidget {
  final CartSummary cart;
  final ValueChanged<String> onApply;
  final VoidCallback onEnterCode;
  const _CouponChips(
      {required this.cart, required this.onApply, required this.onEnterCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers =
        ref.watch(availableCouponsProvider).asData?.value ?? const [];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16, AppSpacing.s16, AppSpacing.s16, 0),
        child: Text('Coupons for you',
            style: AppTextStyles.h2
                .copyWith(fontSize: 14, fontWeight: FontWeight.w800)),
      ),
      SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
          children: [
            for (final o in offers)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s8),
                child: _chip(
                  applied: cart.couponCode == o.code,
                  label: cart.couponCode == o.code
                      ? '✓ ${o.code} · −₹${cart.couponDiscount}'
                      : o.code,
                  onTap: () {
                    if (cart.couponCode != o.code) onApply(o.code);
                  },
                ),
              ),
            _chip(applied: false, label: '＋ Enter code', onTap: onEnterCode),
          ],
        ),
      ),
    ]);
  }

  Widget _chip(
      {required bool applied,
      required String label,
      required VoidCallback onTap}) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: applied ? const Color(0xFFDFF3E7) : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.r100),
          border: Border.all(
              color:
                  applied ? const Color(0xFF36B665) : const Color(0xFFC9BFAD),
              width: 1.4),
        ),
        child: Text(label,
            style: AppTextStyles.captionMed.copyWith(
                fontWeight: FontWeight.w800,
                color: applied
                    ? const Color(0xFF1F7A43)
                    : const Color(0xFF428AC7))),
      ),
    );
  }
}

/// D → the itemised receipt ticket with perforation notches; coupon rides the
/// ticket as a dashed green tag (B's applied-state tick + remove).
class _ReceiptTicket extends ConsumerWidget {
  final CartSummary cart;
  final BrandPalette palette;
  final VoidCallback onRemoveCoupon;
  final ValueChanged<String> onRemoveItem;
  final VoidCallback onViewCoupons;
  final ValueChanged<CartItem> onReassign;

  const _ReceiptTicket({
    required this.cart,
    required this.palette,
    required this.onRemoveCoupon,
    required this.onRemoveItem,
    required this.onViewCoupons,
    required this.onReassign,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn =
        ref.watch(authProvider).status == AuthStatus.authenticated;
    final family =
        ref.watch(familyProvider).asData?.value ?? const <FamilyMember>[];
    final meName = ref.watch(meProvider).maybeWhen(
        data: (m) => (m?.name?.trim().isNotEmpty ?? false)
            ? m!.name!.split(' ').first
            : 'Me',
        orElse: () => 'Me');
    String memberName(String? id) {
      if (id == null) return meName;
      return family.where((f) => f.id == id).map((f) => f.name).firstOrNull ??
          'Member';
    }
    final mrpTotal = cart.itemsTotal + cart.discount;
    return Stack(children: [
      Container(
        margin: const EdgeInsets.fromLTRB(
            AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, AppSpacing.s12),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, AppSpacing.s8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, 7)),
          ],
        ),
        child: Column(children: [
          for (final item in cart.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(item.itemName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                              fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ),
                    if (item.mrp > item.price)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text('₹${item.mrp}',
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                color: AppColors.textDisabled,
                                decoration: TextDecoration.lineThrough)),
                      ),
                    Text('₹${item.price}',
                        style: AppTextStyles.body.copyWith(
                            fontSize: 12.5, fontWeight: FontWeight.w800)),
                    Pressable(
                      onTap: () => onRemoveItem(item.id),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.close,
                            size: 15, color: AppColors.textDisabled),
                      ),
                    ),
                  ]),
                  if (loggedIn)
                    Pressable(
                      onTap: () => onReassign(item),
                      child: Container(
                        margin: const EdgeInsets.only(top: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF4FB),
                          borderRadius:
                              BorderRadius.circular(AppRadius.r100),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(
                              '👤 For: ${memberName(item.familyMemberId)}',
                              style: AppTextStyles.caption.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: palette.primaryDark)),
                          Icon(Icons.arrow_drop_down,
                              size: 14, color: palette.primaryDark),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
          const _DashedLine(),
          _line('MRP total', '₹$mrpTotal', strike: true),
          if (cart.discount > 0)
            _line('Catalogue discount', '−₹${cart.discount}', green: true),
          if (cart.groupDiscount > 0)
            _line('👨‍👩‍👧 Family booking offer', '−₹${cart.groupDiscount}',
                green: true),
          if (cart.couponCode != null)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 5),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8, vertical: AppSpacing.s8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FAF3),
                borderRadius: BorderRadius.circular(AppRadius.r12),
                border:
                    Border.all(color: const Color(0xFF36B665), width: 1.4),
              ),
              child: Row(children: [
                Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: Color(0xFF36B665), shape: BoxShape.circle),
                  child:
                      const Icon(Icons.check, size: 12, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(cart.couponCode!,
                    style: AppTextStyles.captionMed.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: const Color(0xFF1F7A43))),
                const Spacer(),
                Text('−₹${cart.couponDiscount}',
                    style: AppTextStyles.captionMed.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F7A43))),
                Pressable(
                  onTap: onRemoveCoupon,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.close,
                        size: 14, color: Color(0xFFE4574F)),
                  ),
                ),
              ]),
            ),
          if (cart.walletApplied > 0)
            _line('Wallet', '−₹${cart.walletApplied}', green: true),
          _line('Home collection', 'FREE'),
          const _DashedLine(),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(children: [
              Text('To pay',
                  style: AppTextStyles.body
                      .copyWith(fontSize: 14, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('₹${cart.payable}',
                  style: AppTextStyles.body
                      .copyWith(fontSize: 14, fontWeight: FontWeight.w800)),
            ]),
          ),
          Pressable(
            onTap: onViewCoupons,
            child: Padding(
              padding: const EdgeInsets.only(
                  top: AppSpacing.s8, bottom: AppSpacing.s4),
              child: Row(children: [
                Text('View all coupons',
                    style: AppTextStyles.captionMed.copyWith(
                        fontWeight: FontWeight.w800, color: palette.primary)),
                const Spacer(),
                Icon(Icons.chevron_right, size: 17, color: palette.primary),
              ]),
            ),
          ),
        ]),
      ),
      // Perforation notches over the card edges.
      const Positioned(left: 8, top: 0, bottom: 0, child: Center(child: _Notch())),
      const Positioned(
          right: 8, top: 0, bottom: 0, child: Center(child: _Notch())),
    ]);
  }

  Widget _line(String label, String value,
      {bool green = false, bool strike = false}) {
    final color = green ? const Color(0xFF1F7A43) : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text(label,
            style: AppTextStyles.caption
                .copyWith(fontSize: 11.5, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: AppTextStyles.captionMed.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: strike ? AppColors.textDisabled : color,
                decoration: strike
                    ? TextDecoration.lineThrough
                    : TextDecoration.none)),
      ]),
    );
  }
}

class _Notch extends StatelessWidget {
  const _Notch();

  @override
  Widget build(BuildContext context) => Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
            color: Color(0xFFFAF3EA), shape: BoxShape.circle),
      );
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: SizedBox(
        height: 1.5,
        width: double.infinity,
        child: CustomPaint(painter: _DashPainter()),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEDE5D6)
      ..strokeWidth = 1.5;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 6, 0), paint);
      x += 11;
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter old) => false;
}

/// B → wallet toggle card (server clamps; hidden for guests/zero balances).
class _WalletCard extends ConsumerWidget {
  const _WalletCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn =
        ref.watch(authProvider).status == AuthStatus.authenticated;
    final balance = ref
        .watch(walletProvider)
        .maybeWhen(data: (w) => w?.balance ?? 0, orElse: () => 0.0);
    final applied =
        ref.watch(cartProvider).asData?.value?.walletApplied ?? 0;
    if (!loggedIn || (balance <= 0 && applied <= 0)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.s16, 0, AppSpacing.s16, AppSpacing.s12),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16, vertical: AppSpacing.s4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x10000000), blurRadius: 14, offset: Offset(0, 5)),
        ],
      ),
      child: Row(children: [
        const Icon(Icons.account_balance_wallet_outlined,
            size: 19, color: AppColors.textPrimary),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Text(
              applied > 0
                  ? 'Wallet: ₹${applied.toStringAsFixed(0)} applied'
                  : 'Use wallet balance (₹${balance.toStringAsFixed(0)})',
              style: AppTextStyles.body
                  .copyWith(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
        Switch(
          value: applied > 0,
          activeTrackColor: const Color(0xFF36B665),
          onChanged: (on) => ref
              .read(cartProvider.notifier)
              .applyWalletPoints(on ? balance : 0),
        ),
      ]),
    );
  }
}

/// C → trust row.
class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('🏠', 'Free home collection'),
      ('🧪', 'NABL certified'),
      ('⏱️', 'Reports in 6h'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Row(children: [
        for (final (i, it) in items.indexed) ...[
          if (i > 0) const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Column(children: [
                Text(it.$1, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 3),
                Text(it.$2,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary)),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}

/// D → swipe-to-book slider: drag the knob past ~75% to check out.
class _SwipeToBook extends StatefulWidget {
  final num amount;
  final Future<void> Function() onComplete;
  const _SwipeToBook({required this.amount, required this.onComplete});

  @override
  State<_SwipeToBook> createState() => _SwipeToBookState();
}

class _SwipeToBookState extends State<_SwipeToBook>
    with SingleTickerProviderStateMixin {
  static const _knob = 44.0;
  double _drag = 0;
  bool _busy = false;

  late final AnimationController _nudge = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _nudge.stop();
    } else if (!_nudge.isAnimating) {
      _nudge.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _nudge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      color: const Color(0xFFFAF3EA),
      padding: EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, 12 + bottomPad),
      child: LayoutBuilder(builder: (context, constraints) {
        final track = constraints.maxWidth - _knob - 12;
        return GestureDetector(
          onHorizontalDragUpdate: (d) => setState(
              () => _drag = (_drag + d.delta.dx).clamp(0.0, track)),
          onHorizontalDragEnd: (_) async {
            if (_drag > track * 0.75 && !_busy) {
              setState(() => _busy = true);
              await widget.onComplete();
              if (mounted) {
                setState(() {
                  _busy = false;
                  _drag = 0;
                });
              }
            } else {
              setState(() => _drag = 0);
            }
          },
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(AppRadius.r100),
            ),
            child: Stack(alignment: Alignment.center, children: [
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                          _busy ? 'Opening booking…' : 'Swipe to book',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.button.copyWith(
                              color: const Color(0xFFE8EEF5),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    Text('· ₹${widget.amount}',
                        style: AppTextStyles.button.copyWith(
                            color: const Color(0xFF9FD6B4),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _nudge,
                builder: (context, child) => Positioned(
                  left: 6 + _drag + (_drag == 0 ? 8 * _nudge.value : 0),
                  child: child!,
                ),
                child: Container(
                  width: _knob,
                  height: _knob,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF36B665), Color(0xFF2A9C54)]),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        );
      }),
    );
  }
}

/// B → "all coupons" bottom sheet: manual code + server-driven offers.
class _CouponSheet extends ConsumerStatefulWidget {
  final ValueChanged<String> onApply;
  const _CouponSheet({required this.onApply});

  @override
  ConsumerState<_CouponSheet> createState() => _CouponSheetState();
}

class _CouponSheetState extends ConsumerState<_CouponSheet> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offers =
        ref.watch(availableCouponsProvider).asData?.value ?? const [];
    final applied = ref.watch(cartProvider).asData?.value?.couponCode;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, 16 + bottomInset),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: const Color(0xFFE3E7ED),
                borderRadius: BorderRadius.circular(AppRadius.r100))),
        const SizedBox(height: AppSpacing.s12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Coupons',
              style: AppTextStyles.h2
                  .copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: AppSpacing.s12),
        Row(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFBFCFE),
                borderRadius: BorderRadius.circular(AppRadius.r12),
                border:
                    Border.all(color: const Color(0xFFB9C8D8), width: 1.4),
              ),
              child: TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                style:
                    AppTextStyles.body.copyWith(fontSize: 13, letterSpacing: 1),
                decoration: InputDecoration(
                  hintText: 'Enter coupon code',
                  hintStyle: AppTextStyles.body
                      .copyWith(fontSize: 13, color: AppColors.textDisabled),
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12, vertical: 11),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          PrimaryButton(
            label: 'APPLY',
            onPressed: () {
              final code = _code.text.trim().toUpperCase();
              if (code.isNotEmpty) widget.onApply(code);
            },
          ),
        ]),
        const SizedBox(height: AppSpacing.s12),
        for (final o in offers)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: AppSpacing.s8),
            padding: const EdgeInsets.all(AppSpacing.s12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              border: Border.all(
                  color: applied == o.code
                      ? const Color(0xFF36B665)
                      : const Color(0xFFCBD7E4),
                  width: 1.4),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s8, vertical: 2),
                        decoration: BoxDecoration(
                          color: applied == o.code
                              ? const Color(0xFFDFF3E7)
                              : const Color(0xFFEAF4FB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(o.code,
                            style: AppTextStyles.captionMed.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: applied == o.code
                                    ? const Color(0xFF1F7A43)
                                    : const Color(0xFF428AC7))),
                      ),
                      if (o.description != null) ...[
                        const SizedBox(height: 5),
                        Text(o.description!,
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 10.5,
                                color: AppColors.textSecondary)),
                      ],
                    ]),
              ),
              Pressable(
                onTap: () {
                  if (applied != o.code) widget.onApply(o.code);
                },
                child: Text(applied == o.code ? '✓ APPLIED' : 'APPLY',
                    style: AppTextStyles.captionMed.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2A9C54))),
              ),
            ]),
          ),
      ]),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shopping_cart_outlined,
              size: 64, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.s16),
          Text('Your cart is empty',
              style:
                  AppTextStyles.h3.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.s16),
          SizedBox(
            width: 200,
            child: PrimaryButton(
                label: 'Browse Tests', onPressed: () => context.go('/tests')),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  const _Message({required this.text});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Text(text,
              textAlign: TextAlign.center,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary)),
        ),
      );
}
