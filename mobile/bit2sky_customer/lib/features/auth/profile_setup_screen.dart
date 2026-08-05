import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../providers/brand_palette_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/session_reset.dart';

/// After any login, send new/incomplete users here to fill patient details
/// (name + sex + DOB), then to /home. Existing complete profiles skip straight
/// to /home. Call this instead of `context.go('/home')` after auth succeeds.
Future<void> routeAfterLogin(BuildContext context, WidgetRef ref) async {
  invalidateSessionProviders(ref);
  MeProfile? me;
  var fetchFailed = false;
  try {
    me = await ref.read(meProvider.future);
  } catch (_) {
    fetchFailed = true;
  }
  if (!context.mounted) return;
  // Fail open: a transient profile-fetch failure must NOT trap an already
  // complete profile in an empty setup form. Only a successful fetch that
  // says "incomplete" routes to /auth/setup; the gate re-runs next launch.
  final needsSetup = !fetchFailed && me != null && !me.profileComplete;
  context.go(needsSetup ? '/auth/setup' : '/home');
}

/// Mandatory first-time profile setup, styled per the "Personal Information"
/// reference. Validation is per-field: tapping Sign Up marks each offending
/// input with a red border + inline message and shakes it, so what is
/// missing/wrong is always obvious. Errors clear as the user fixes them.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  static const _canvas = Color(0xFFFAF3EA); // reference cream

  final _name = TextEditingController();
  final _mobileNo = TextEditingController();
  final _email = TextEditingController();
  final _city = TextEditingController();
  final _referral = TextEditingController();
  String? _title; // 'Mr.' | 'Ms.' | 'Other'
  DateTime? _dob;
  bool _busy = false;
  String? _serverError;
  bool _loaded = false;

  /// field key → inline message; a failed submit also bumps [_shakeTick] so
  /// every offending field shakes.
  final Map<String, String> _fieldErrors = {};
  int _shakeTick = 0;

  static final RegExp _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  static const _titleToGender = {
    'Mr.': 'Male',
    'Ms.': 'Female',
    'Other': 'Other',
  };

  @override
  void dispose() {
    _name.dispose();
    _mobileNo.dispose();
    _email.dispose();
    _city.dispose();
    _referral.dispose();
    super.dispose();
  }

  void _prefill(MeProfile? me) {
    if (_loaded || me == null) return;
    _loaded = true;
    _name.text = me.name ?? '';
    _mobileNo.text = me.mobile.replaceFirst('+91', '');
    _email.text = me.email ?? '';
    _title = _titleToGender.entries
        .where((e) => e.value.toLowerCase() == (me.gender ?? '').toLowerCase())
        .map((e) => e.key)
        .firstOrNull;
    _dob = me.dateOfBirth;
  }

  void _clearError(String key) {
    if (_fieldErrors.containsKey(key)) {
      setState(() => _fieldErrors.remove(key));
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 28),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: 'Date of birth',
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
        _fieldErrors.remove('dob');
      });
    }
  }

  Future<void> _save() async {
    final errors = <String, String>{};
    if (_title == null) errors['title'] = 'Please select one';
    if (_name.text.trim().isEmpty) errors['name'] = 'Please enter your name';
    if (_mobileNo.text.trim().length != 10) {
      errors['mobile'] = 'Enter a valid 10-digit mobile number';
    }
    if (_dob == null) errors['dob'] = 'Please select your birthday';
    final email = _email.text.trim();
    if (email.isNotEmpty && !_emailRegex.hasMatch(email)) {
      errors['email'] = 'Enter a valid e-mail address';
    }
    if (errors.isNotEmpty) {
      HapticFeedback.mediumImpact();
      setState(() {
        _fieldErrors
          ..clear()
          ..addAll(errors);
        _shakeTick++;
        _serverError = null;
      });
      return;
    }

    setState(() {
      _busy = true;
      _serverError = null;
      _fieldErrors.clear();
    });
    try {
      final d = _dob!;
      await ref.read(dioClientProvider).raw.put('/users/me', data: {
        'name': _name.text.trim(),
        'mobile': '+91${_mobileNo.text.trim()}',
        if (email.isNotEmpty) 'email': email,
        'gender': _titleToGender[_title],
        'dateOfBirth':
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      });
      await SecureStorageService().saveProfileExtras(
        city: _city.text.trim(),
        referralCode: _referral.text.trim(),
      );
      ref.invalidate(meProvider);
      if (mounted) context.go('/home');
    } catch (e) {
      final conflict = e.toString().contains('409');
      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _busy = false;
          if (conflict) {
            _fieldErrors['mobile'] = 'This mobile number is already registered';
            _shakeTick++;
          } else {
            _serverError = 'Could not save. Try again.';
          }
        });
      }
    }
  }

  String? get _dobLabel {
    final d = _dob;
    if (d == null) return null;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Widget _inlineError(String key) {
    final msg = _fieldErrors[key];
    if (msg == null) return const SizedBox.shrink();
    return Padding(
      padding:
          const EdgeInsets.only(bottom: AppSpacing.s6, left: AppSpacing.s4),
      child: Row(children: [
        const Icon(Icons.error_outline, size: 13, color: AppColors.errorRed),
        const SizedBox(width: 4),
        Text(msg,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.errorRed, fontSize: 12)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    _prefill(
        ref.watch(meProvider).maybeWhen(data: (m) => m, orElse: () => null));
    final palette = ref.watch(brandPaletteProvider);

    return Scaffold(
      backgroundColor: _canvas,
      // No back — completing this is required before using the app.
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s20, AppSpacing.s16, AppSpacing.s20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Information',
                      style: AppTextStyles.h1.copyWith(
                        color: palette.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    const _FieldLabel('How should we address you?'),
                    _inlineError('title'),
                    _Shake(
                      tick: _shakeTick,
                      active: _fieldErrors.containsKey('title'),
                      child: Row(
                        children: [
                          for (final t in _titleToGender.keys) ...[
                            _TitleChip(
                              label: t,
                              selected: _title == t,
                              accent: palette.primary,
                              error: _fieldErrors.containsKey('title'),
                              onTap: () => setState(() {
                                _title = t;
                                _fieldErrors.remove('title');
                              }),
                            ),
                            const SizedBox(width: AppSpacing.s12),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    const _FieldLabel("What's your name?"),
                    _inlineError('name'),
                    _Shake(
                      tick: _shakeTick,
                      active: _fieldErrors.containsKey('name'),
                      child: _PillField(
                        controller: _name,
                        hint: 'Enter your full name',
                        capitalization: TextCapitalization.words,
                        error: _fieldErrors.containsKey('name'),
                        onChanged: (_) => _clearError('name'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    const _FieldLabel("What's your mobile number?"),
                    _inlineError('mobile'),
                    _Shake(
                      tick: _shakeTick,
                      active: _fieldErrors.containsKey('mobile'),
                      child: _MobilePill(
                        controller: _mobileNo,
                        error: _fieldErrors.containsKey('mobile'),
                        onChanged: (_) => _clearError('mobile'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    const _FieldLabel("When's your birthday?"),
                    _inlineError('dob'),
                    _Shake(
                      tick: _shakeTick,
                      active: _fieldErrors.containsKey('dob'),
                      child: _PillTap(
                        onTap: _pickDob,
                        value: _dobLabel,
                        hint: 'Date/ Month/ Year (DD/MM/YYYY)',
                        error: _fieldErrors.containsKey('dob'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    const _FieldLabel('Where should we e-mail your reports?'),
                    _inlineError('email'),
                    _Shake(
                      tick: _shakeTick,
                      active: _fieldErrors.containsKey('email'),
                      child: _PillField(
                        controller: _email,
                        hint: 'Enter your e-mail ID',
                        keyboard: TextInputType.emailAddress,
                        error: _fieldErrors.containsKey('email'),
                        onChanged: (_) => _clearError('email'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    const _FieldLabel('Which city are you in?'),
                    _PillField(
                      controller: _city,
                      hint: 'Enter your city',
                      capitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    const _FieldLabel('Referral code (optional)'),
                    _PillField(
                      controller: _referral,
                      hint: 'Enter code',
                      capitalization: TextCapitalization.characters,
                    ),
                    if (_serverError != null) ...[
                      const SizedBox(height: AppSpacing.s16),
                      Text(_serverError!,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.errorRed)),
                    ],
                    const SizedBox(height: AppSpacing.s24),
                  ],
                ),
              ),
            ),
            // Full-width CTA parked at the bottom, per the reference.
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s20,
                  AppSpacing.s8, AppSpacing.s20, AppSpacing.s16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _busy ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.r16)),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white),
                        )
                      : Text('Sign Up',
                          style: AppTextStyles.button.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal shake that replays whenever [tick] changes while [active].
class _Shake extends StatefulWidget {
  final int tick;
  final bool active;
  final Widget child;
  const _Shake({required this.tick, required this.active, required this.child});

  @override
  State<_Shake> createState() => _ShakeState();
}

class _ShakeState extends State<_Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(covariant _Shake old) {
    super.didUpdateWidget(old);
    if (widget.tick != old.tick && widget.active) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(
            math.sin(_c.value * math.pi * 5) * 7 * (1 - _c.value), 0),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Bold question-style label above each input (reference pattern).
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Text(text,
          style: AppTextStyles.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
    );
  }
}

const _pillShadow = [
  BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 4)),
];

BoxDecoration _pillDecoration(bool error) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      border: Border.all(
          color: error ? AppColors.errorRed : Colors.transparent,
          width: 1.4),
      boxShadow: _pillShadow,
    );

/// White rounded input pill with a soft shadow; red border when [error].
class _PillField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboard;
  final TextCapitalization capitalization;
  final bool error;
  final ValueChanged<String>? onChanged;

  const _PillField({
    required this.controller,
    required this.hint,
    this.keyboard,
    this.capitalization = TextCapitalization.none,
    this.error = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _pillDecoration(error),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        textCapitalization: capitalization,
        onChanged: onChanged,
        style: AppTextStyles.body.copyWith(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.body
              .copyWith(fontSize: 14, color: AppColors.textDisabled),
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16, vertical: 12),
        ),
      ),
    );
  }
}

/// +91 mobile pill (login is email-OTP only, so this is captured here).
class _MobilePill extends StatelessWidget {
  final TextEditingController controller;
  final bool error;
  final ValueChanged<String>? onChanged;
  const _MobilePill(
      {required this.controller, this.error = false, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _pillDecoration(error),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 15,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2.5),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.33, 0.33, 0.66, 0.66],
                colors: [
                  Color(0xFFFF9933),
                  Colors.white,
                  Colors.white,
                  Color(0xFF138808)
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Text('+91',
              style: AppTextStyles.body
                  .copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              onChanged: onChanged,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              style: AppTextStyles.body.copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter your number',
                hintStyle: AppTextStyles.body
                    .copyWith(fontSize: 14, color: AppColors.textDisabled),
                filled: false,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Same pill, but tap-to-pick (birthday); red border when [error].
class _PillTap extends StatelessWidget {
  final VoidCallback onTap;
  final String? value;
  final String hint;
  final bool error;

  const _PillTap({
    required this.onTap,
    required this.value,
    required this.hint,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16, vertical: 12),
        decoration: _pillDecoration(error),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: value == null
                        ? AppColors.textDisabled
                        : AppColors.textPrimary),
              ),
            ),
            Icon(Icons.calendar_today_outlined,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// White rounded "Mr. / Ms." card chip; selected state gets the brand accent;
/// unresolved required choice gets a red outline.
class _TitleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final bool error;
  final VoidCallback onTap;

  const _TitleChip({
    required this.label,
    required this.selected,
    required this.accent,
    this.error = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? accent : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          border: Border.all(
              color: error && !selected
                  ? AppColors.errorRed
                  : Colors.transparent,
              width: 1.4),
          boxShadow: _pillShadow,
        ),
        child: Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
