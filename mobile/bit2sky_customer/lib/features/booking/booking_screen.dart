import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/account_models.dart';
import '../../models/booking_models.dart';
import '../../models/branding_config.dart';
import '../../providers/account_provider.dart';
import '../../providers/app_providers.dart';
import '../../providers/booking_provider.dart';
import '../../providers/brand_palette_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/pressable.dart';
import '../cart/coupons_sheet.dart';
import '../profile/profile_edit_sheet.dart';
import 'razorpay_checkout.dart';

/// Book Collection — single screen (wireframe C). No wizard: members ride in
/// from the cart, address & payment collapse to one line once set, date/time
/// stays open, a "fastest slot" card books the common case in one tap, and a
/// live receipt stub at the bottom shows the whole booking before Confirm.
class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  static const _canvas = Color(0xFFFAF3EA);
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _periods = ['Morning', 'Afternoon', 'Evening'];
  static const _periodIcons = ['🌅', '☀️', '🌇'];

  String? _addressId;
  bool _addressOpen = false;
  DateTime _date = () {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }();
  String? _slot;
  String? _slotId;
  int _period = 0;
  String _pay = 'online';

  final _checkout = RazorpayCheckout();
  CreateBookingResult? _pendingPayment;
  bool _paying = false;

  @override
  void dispose() {
    _checkout.dispose();
    super.dispose();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _selfReady {
    final me =
        ref.read(meProvider).maybeWhen(data: (m) => m, orElse: () => null);
    return me?.age != null && (me?.gender?.isNotEmpty ?? false);
  }

  bool get _ready => _addressId != null && _slotId != null;

  Future<void> _placeOrder() async {
    if (_pendingPayment != null) {
      _openPaymentSheet(_pendingPayment!);
      return;
    }
    // Labs need age + sex for the account holder's own samples.
    if (!_selfReady) {
      await showEditProfileSheet(context);
      if (!_selfReady) return;
    }

    final result = await ref.read(bookingControllerProvider.notifier).create(
          BookingDraft(
            date: _date,
            timeSlot: _slot,
            slotId: _slotId,
            addressId: _addressId,
            familyMemberId: null,
            paymentMethod: _pay == 'online' ? 'online' : 'cod',
          ),
        );
    if (result == null || !mounted) return;

    // Hand the chosen address + slot to the confirmation screen (the create
    // response doesn't echo them back).
    final addr = ref
        .read(addressProvider)
        .asData
        ?.value
        .where((a) => a.id == _addressId)
        .firstOrNull;
    ref.read(lastBookingUiContextProvider.notifier).set((
      addressType: addr?.type,
      addressLine: addr?.fullLine,
      slotTime: _slot,
    ));

    if (_pay != 'online') {
      context.go('/booking/confirm');
      return;
    }
    if (result.amountPayable <= 0) {
      await _confirmPayment(result, '', '');
      return;
    }
    if (!result.canPayOnline) {
      _snack('Online payment is unavailable right now — please pay on '
          'sample collection.');
      context.go('/booking/confirm');
      return;
    }
    _openPaymentSheet(result);
  }

  void _openPaymentSheet(CreateBookingResult result) {
    final branding = ref.read(brandingProvider).maybeWhen(
        data: (b) => b, orElse: () => BrandingConfig.fallback);
    final me =
        ref.read(meProvider).maybeWhen(data: (m) => m, orElse: () => null);
    setState(() {
      _pendingPayment = result;
      _paying = true;
    });
    _checkout.open(
      result: result,
      branding: branding,
      contact: me?.mobile,
      email: me?.email,
      onSuccess: (paymentId, signature) =>
          _confirmPayment(result, paymentId, signature),
      onFailure: (message) {
        if (!mounted) return;
        setState(() => _paying = false);
        _snack(message);
      },
    );
  }

  Future<void> _confirmPayment(
      CreateBookingResult result, String paymentId, String signature) async {
    final ok = await ref
        .read(bookingControllerProvider.notifier)
        .confirm(result.bookingId, paymentId, signature);
    if (!mounted) return;
    setState(() => _paying = false);
    if (ok) {
      _pendingPayment = null;
      context.go('/booking/confirm?paid=1');
    } else {
      _snack('Payment received but confirmation failed — check Bookings in a '
          'moment or contact support. You have not been charged twice.');
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating, content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(brandPaletteProvider);
    final booking = ref.watch(bookingControllerProvider);
    final cart = ref.watch(cartProvider).asData?.value;
    final me =
        ref.watch(meProvider).maybeWhen(data: (m) => m, orElse: () => null);
    final family = ref.watch(familyProvider).maybeWhen(
        data: (f) => f, orElse: () => const <FamilyMember>[]);
    final addresses = ref.watch(addressProvider).asData?.value;

    // Auto-select the first saved address so the accordion starts collapsed.
    if (_addressId == null && (addresses?.isNotEmpty ?? false)) {
      _addressId = addresses!.first.id;
    }
    final selectedAddr =
        addresses?.where((a) => a.id == _addressId).firstOrNull;

    // Distinct member names from the cart's per-member lines.
    final memberNames = <String>{};
    for (final it in cart?.items ?? const []) {
      if (it.familyMemberId == null) {
        memberNames.add((me?.name?.trim().isNotEmpty ?? false)
            ? me!.name!.split(' ').first
            : 'Me');
      } else {
        memberNames.add(family
                .where((m) => m.id == it.familyMemberId)
                .map((m) => m.name.split(' ').first)
                .firstOrNull ??
            'Member');
      }
    }

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, 0),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go('/home'),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Text('Book Collection',
                      style: AppTextStyles.h2.copyWith(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  if (memberNames.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.r100),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x0D000000),
                              blurRadius: 8,
                              offset: Offset(0, 3)),
                        ],
                      ),
                      child: Text('👤 ${memberNames.join(' + ')}',
                          style: AppTextStyles.caption.copyWith(
                              fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 20),
                children: [
                  _FastestSlotCard(
                    onBook: (date, slotId, time) => setState(() {
                      _date = date;
                      _slotId = slotId;
                      _slot = time;
                      _period = 0;
                    }),
                  ),
                  // ── address accordion ──
                  _AccordionCard(
                    leading: selectedAddr != null && !_addressOpen
                        ? const _Dot(check: true)
                        : const _Dot(),
                    title: 'Collection address',
                    summary: selectedAddr == null
                        ? 'choose ▾'
                        : '${_addrEmoji(selectedAddr.type)} ${selectedAddr.type} · ${selectedAddr.fullLine.split(',').first} ▾',
                    open: _addressOpen || selectedAddr == null,
                    onToggle: () =>
                        setState(() => _addressOpen = !_addressOpen),
                    child: Column(
                      children: [
                        if (addresses == null)
                          const Padding(
                            padding: EdgeInsets.all(AppSpacing.s12),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else ...[
                          for (final (i, a) in addresses.indexed) ...[
                            if (i > 0) const _DashedDivider(),
                            _AddressRow(
                              address: a,
                              selected: _addressId == a.id,
                              onTap: () => setState(() {
                                _addressId = a.id;
                                _addressOpen = false;
                              }),
                            ),
                          ],
                          Pressable(
                            onTap: () => context.push('/addresses'),
                            child: Container(
                              margin:
                                  const EdgeInsets.only(top: AppSpacing.s8),
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.s8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: const Color(0xFFB9C6D2),
                                    width: 1.6,
                                    style: BorderStyle.solid),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.r12),
                              ),
                              child: Text('+ Add a new address',
                                  style: AppTextStyles.captionMed.copyWith(
                                      color: palette.primary,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // ── date & time (always open) ──
                  _AccordionCard(
                    leading: _slotId != null
                        ? const _Dot(check: true)
                        : const _Dot(),
                    title: 'Date & time',
                    summary: _slotId == null
                        ? 'choose'
                        : '${_weekdays[_date.weekday - 1]} ${_date.day} · $_slot',
                    open: true,
                    onToggle: null,
                    child: _buildSlotArea(palette),
                  ),
                  // ── payment: inline pills ──
                  _AccordionCard(
                    leading: const _Dot(text: '₹'),
                    title: 'Payment',
                    open: false,
                    onToggle: null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PayPill(
                          label: '💳 Online',
                          on: _pay == 'online',
                          onTap: () => setState(() => _pay = 'online'),
                        ),
                        const SizedBox(width: 5),
                        _PayPill(
                          label: '💵 At collection',
                          on: _pay == 'cash',
                          onTap: () => setState(() => _pay = 'cash'),
                        ),
                      ],
                    ),
                    child: const SizedBox.shrink(),
                  ),
                  // ── coupons & offers ──
                  _AccordionCard(
                    leading: const _Dot(text: '🎟'),
                    title: 'Coupons & offers',
                    summary: cart?.couponCode == null
                        ? 'choose ▾'
                        : '${cart!.couponCode} · −₹${cart.couponDiscount.round()} ▾',
                    open: cart?.couponCode != null,
                    onToggle: () => showCouponsSheet(context),
                    child: cart?.couponCode == null
                        ? const SizedBox.shrink()
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s12,
                                vertical: AppSpacing.s8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9F8EE),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.r12),
                              border: Border.all(
                                  color: const Color(0xFF2A9C54),
                                  width: 1.6),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(cart!.couponCode!,
                                          style: AppTextStyles.h4
                                              .copyWith(
                                                  fontSize: 12.5,
                                                  fontWeight:
                                                      FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                  color: const Color(
                                                      0xFF1F7A42))),
                                      Text(
                                          'Saving ₹${cart.couponDiscount.round()} on this booking',
                                          style: AppTextStyles.caption
                                              .copyWith(
                                                  fontSize: 10,
                                                  color: const Color(
                                                      0xFF3B7A55))),
                                    ],
                                  ),
                                ),
                                Pressable(
                                  onTap: () => ref
                                      .read(cartProvider.notifier)
                                      .removeCoupon(),
                                  child: const Padding(
                                    padding:
                                        EdgeInsets.all(AppSpacing.s4),
                                    child: Text('✕',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1F7A42))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  if (booking.hasError)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, 0),
                      child: Text(booking.error.toString(),
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.errorRed)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _ReceiptBar(
        memberNames: memberNames,
        addressType: selectedAddr?.type,
        slotLabel: _slotId == null
            ? null
            : '${_weekdays[_date.weekday - 1]} ${_date.day} · $_slot',
        pay: _pay,
        cart: cart,
        pending: _pendingPayment,
        loading: booking.isLoading || _paying,
        enabled: _ready || _pendingPayment != null,
        onConfirm: _placeOrder,
        palette: palette,
      ),
    );
  }

  String _addrEmoji(String type) => switch (type.toLowerCase()) {
        'home' => '🏠',
        'office' => '🏢',
        'work' => '🏢',
        _ => '📍',
      };

  Widget _buildSlotArea(dynamic palette) {
    final now = DateTime.now();
    final days = List.generate(
        7, (i) => DateTime(now.year, now.month, now.day + i + 1));
    final slotsAsync = ref.watch(slotsProvider(_date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 62,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s8),
            itemBuilder: (_, i) {
              final d = days[i];
              final on = _sameDay(d, _date);
              return Pressable(
                onTap: () => setState(() {
                  _date = d;
                  _slot = null;
                  _slotId = null;
                }),
                child: Container(
                  width: 56,
                  decoration: BoxDecoration(
                    gradient: on
                        ? LinearGradient(
                            colors: [palette.primary, palette.primaryDark])
                        : null,
                    color: on ? null : const Color(0xFFF7F1E6),
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_weekdays[d.weekday - 1],
                          style: AppTextStyles.caption.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: on
                                  ? Colors.white70
                                  : AppColors.textSecondary)),
                      const SizedBox(height: 1),
                      Text('${d.day}',
                          style: AppTextStyles.h3.copyWith(
                              fontWeight: FontWeight.w800,
                              color:
                                  on ? Colors.white : AppColors.textPrimary)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Row(
          children: [
            for (var i = 0; i < _periods.length; i++)
              Expanded(
                child: Pressable(
                  onTap: () => setState(() => _period = i),
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 7 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _period == i
                          ? const Color(0xFFEDF4FB)
                          : const Color(0xFFF7F1E6),
                      borderRadius: BorderRadius.circular(AppRadius.r100),
                      border: Border.all(
                          color: _period == i
                              ? palette.primary
                              : Colors.transparent,
                          width: 1.5),
                    ),
                    child: Text('${_periodIcons[i]} ${_periods[i]}',
                        style: AppTextStyles.caption.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _period == i
                                ? palette.primaryDark
                                : AppColors.textSecondary)),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        slotsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.s16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Text('Could not load slots.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          data: (slots) {
            final forPeriod =
                slots.where((s) => s.period == _periods[_period]).toList();
            if (forPeriod.isEmpty) {
              return Text('No slots for this time of day.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary));
            }
            return Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                for (final s in forPeriod)
                  Pressable(
                    onTap: s.available
                        ? () => setState(() {
                              _slotId = s.id;
                              _slot = s.startTime;
                            })
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: _slotId == s.id
                            ? LinearGradient(colors: [
                                palette.primary,
                                palette.primaryDark
                              ])
                            : null,
                        color: _slotId == s.id
                            ? null
                            : s.available
                                ? const Color(0xFFF7F1E6)
                                : const Color(0xFFF2EDE2),
                        borderRadius: BorderRadius.circular(AppRadius.r100),
                      ),
                      child: Text(s.startTime,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _slotId == s.id
                                ? Colors.white
                                : s.available
                                    ? AppColors.textPrimary
                                    : AppColors.textDisabled,
                            decoration: s.available
                                ? null
                                : TextDecoration.lineThrough,
                          )),
                    ),
                  ),
              ],
            );
          },
        ),
        if (_period == 0) ...[
          const SizedBox(height: AppSpacing.s12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8EF),
              borderRadius: BorderRadius.circular(AppRadius.r12),
              border: Border.all(color: const Color(0xFFBFE8CC), width: 1.3),
            ),
            child: Text(
              _slot != null
                  ? '⏱ Fasting tests? Stop eating by ${_fastingCutoff(_slot!)} the night before.'
                  : '⏱ Fasting tests need 12–14 hrs — morning slots are best.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F7A43)),
            ),
          ),
        ],
      ],
    );
  }

  /// "07:00" → "7 PM" (12 hrs before the slot).
  String _fastingCutoff(String slot) {
    final h = int.tryParse(slot.split(':').first) ?? 8;
    final cutoff = (h - 12) % 24;
    final display = cutoff == 0
        ? '12 AM'
        : cutoff > 12
            ? '${cutoff - 12} PM'
            : '$cutoff ${cutoff == 12 ? 'PM' : 'AM'}';
    return display;
  }
}

// ── Fastest slot card ───────────────────────────────────────────────────────
class _FastestSlotCard extends ConsumerWidget {
  final void Function(DateTime date, String slotId, String time) onBook;
  const _FastestSlotCard({required this.onBook});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Date-only value: a raw DateTime.now() changes every rebuild, giving the
    // provider family a fresh key each frame (endless refetch, no data).
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final slots = ref.watch(slotsProvider(tomorrow)).asData?.value;
    final first = slots?.where((s) => s.available).firstOrNull;
    if (first == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, 0),
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF2A9C54), Color(0xFF1F7A42)]),
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x552A9C54),
              blurRadius: 18,
              offset: Offset(0, 7)),
        ],
      ),
      child: Row(
        children: [
          const Text('⚡', style: TextStyle(fontSize: 22)),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fastest collection: tomorrow ${first.startTime}',
                    style: AppTextStyles.h4.copyWith(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800)),
                Text('Fasting-friendly morning slot',
                    style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFFD7F5E2), fontSize: 10.5)),
              ],
            ),
          ),
          Pressable(
            onTap: () => onBook(tomorrow, first.id, first.startTime),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.r100),
              ),
              child: Text('Book this',
                  style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF1F7A42),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── shared pieces ───────────────────────────────────────────────────────────
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool check;
  final String? text;
  const _Dot({this.check = false, this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: check ? const Color(0xFF2A9C54) : const Color(0xFF3E7FBE),
        shape: BoxShape.circle,
      ),
      child: check
          ? const Icon(Icons.check, size: 13, color: Colors.white)
          : Text(text ?? '•',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
    );
  }
}

class _AccordionCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? summary;
  final Widget? trailing;
  final bool open;
  final VoidCallback? onToggle;
  final Widget child;
  const _AccordionCard({
    required this.leading,
    required this.title,
    this.summary,
    this.trailing,
    required this.open,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 14, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Pressable(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s12, vertical: AppSpacing.s12),
              child: Row(
                children: [
                  leading,
                  const SizedBox(width: AppSpacing.s8),
                  Text(title,
                      style: AppTextStyles.h4
                          .copyWith(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  if (trailing != null)
                    trailing!
                  else if (summary != null)
                    Flexible(
                      child: Text(summary!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary)),
                    ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: open
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(AppSpacing.s12, 0,
                        AppSpacing.s12, AppSpacing.s12),
                    decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(
                              color: Color(0xFFF3EDE2), width: 1.4)),
                    ),
                    child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.s12),
                        child: child),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final Address address;
  final bool selected;
  final VoidCallback onTap;
  const _AddressRow(
      {required this.address, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEDF4FB),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                  address.type.toLowerCase() == 'home' ? '🏠' : '🏢',
                  style: const TextStyle(fontSize: 15)),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address.type, style: AppTextStyles.h4),
                  Text(address.fullLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20,
              color: selected
                  ? const Color(0xFF2A9C54)
                  : AppColors.borderStrong,
            ),
          ],
        ),
      ),
    );
  }
}

class _PayPill extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _PayPill({required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: on ? const Color(0xFFEDF4FB) : const Color(0xFFF4F1EA),
          borderRadius: BorderRadius.circular(AppRadius.r100),
          border: Border.all(
              color: on ? const Color(0xFF3E7FBE) : Colors.transparent,
              width: 1.4),
        ),
        child: Text(label,
            style: AppTextStyles.caption.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: on ? const Color(0xFF2C5F94) : AppColors.textSecondary)),
      ),
    );
  }
}

/// Live receipt stub: dashed top edge, the whole booking at a glance, and the
/// confirm CTA.
class _ReceiptBar extends StatelessWidget {
  final Set<String> memberNames;
  final String? addressType;
  final String? slotLabel;
  final String pay;
  final dynamic cart;
  final CreateBookingResult? pending;
  final bool loading;
  final bool enabled;
  final VoidCallback onConfirm;
  final dynamic palette;
  const _ReceiptBar({
    required this.memberNames,
    required this.addressType,
    required this.slotLabel,
    required this.pay,
    required this.cart,
    required this.pending,
    required this.loading,
    required this.enabled,
    required this.onConfirm,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final total = pending?.amountPayable ?? cart?.payable ?? 0;
    final items = cart?.items.length ?? 0;
    final saved = (cart?.discount ?? 0) +
        (cart?.couponDiscount ?? 0) +
        (cart?.groupDiscount ?? 0);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
            top: BorderSide(color: Color(0xFFD8CDBA), width: 1.6)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, AppSpacing.s12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (memberNames.isNotEmpty)
                    _stub('👤 ${memberNames.join(' + ')}'),
                  _stub(addressType == null ? '📍 —' : '🏠 $addressType'),
                  _stub(slotLabel == null ? '📅 pick a slot' : '📅 $slotLabel'),
                  _stub(pay == 'online' ? '💳 Online' : '💵 Cash'),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      saved > 0
                          ? '$items item${items == 1 ? '' : 's'} · saving ₹${saved.round()}'
                          : '$items item${items == 1 ? '' : 's'}',
                      style: AppTextStyles.caption.copyWith(
                          fontSize: 11, color: AppColors.textSecondary)),
                  Text('₹${(cart?.itemsTotal ?? total).round()}',
                      style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary)),
                ],
              ),
              if ((cart?.couponCode) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('🎟 ${cart!.couponCode}',
                          style: AppTextStyles.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1F7A42))),
                      Text('− ₹${cart.couponDiscount.round()}',
                          style: AppTextStyles.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1F7A42))),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('To pay',
                        style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                    Text('₹${total.round()}',
                        style: AppTextStyles.h3.copyWith(
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Pressable(
                onTap: enabled && !loading ? onConfirm : null,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: enabled
                        ? LinearGradient(
                            colors: [palette.primary, palette.primaryDark])
                        : null,
                    color: enabled ? null : const Color(0xFFD9D2C4),
                    borderRadius: BorderRadius.circular(AppRadius.r100),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white))
                      : Text(
                          pending != null
                              ? 'Retry Payment · ₹${pending!.amountPayable}'
                              : 'Confirm Booking →',
                          style: AppTextStyles.button.copyWith(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stub(String text) => Text(text,
      style: AppTextStyles.caption.copyWith(
          fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF75808D)));
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 8).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
                width: 4.5, height: 1.4, color: const Color(0xFFEDE4D3)),
          ),
        );
      },
    );
  }
}
