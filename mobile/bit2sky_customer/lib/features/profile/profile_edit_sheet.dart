import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/buttons.dart';

/// Edit the signed-in user's profile. Gender + DOB are collected because the
/// user is also a patient — labs need them to interpret results.
Future<void> showEditProfileSheet(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _EditProfileSheet(),
    );

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet();

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  String? _gender;
  DateTime? _dob;
  bool _busy = false;
  String? _error;
  bool _loaded = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _prefill(MeProfile? me) {
    if (_loaded || me == null) return;
    _loaded = true;
    _name.text = me.name ?? '';
    _email.text = me.email ?? '';
    _gender = me.gender;
    _dob = me.dateOfBirth;
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
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return setState(() => _error = 'Enter your name.');
    if (_gender == null) return setState(() => _error = 'Select gender.');
    if (_dob == null) return setState(() => _error = 'Select date of birth.');

    setState(() { _busy = true; _error = null; });
    try {
      final d = _dob!;
      await ref.read(dioClientProvider).raw.put('/users/me', data: {
        'name': _name.text.trim(),
        if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
        'gender': _gender,
        'dateOfBirth':
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      });
      ref.invalidate(meProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() { _busy = false; _error = 'Could not save. Try again.'; });
    }
  }

  String _dobLabel() {
    final d = _dob;
    if (d == null) return 'Select date of birth';
    final age = DateTime.now().year - d.year;
    return '${d.day}/${d.month}/${d.year}  ·  ~$age yrs';
  }

  @override
  Widget build(BuildContext context) {
    _prefill(ref.watch(meProvider).maybeWhen(data: (m) => m, orElse: () => null));
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.s20, AppSpacing.s16, AppSpacing.s20,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.s20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Personal details', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text('Your age and sex help labs interpret your reports correctly.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.s20),
            TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name *')),
            const SizedBox(height: AppSpacing.s12),
            TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email (optional)')),
            const SizedBox(height: AppSpacing.s16),
            Text('Gender *', style: AppTextStyles.label),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: ['Male', 'Female', 'Other'].map((g) {
                final on = _gender == g;
                return ChoiceChip(
                  label: Text(g),
                  selected: on,
                  onSelected: (_) => setState(() => _gender = g),
                  selectedColor: AppColors.teal50,
                  labelStyle: TextStyle(
                      color: on ? AppColors.teal700 : AppColors.textPrimary,
                      fontWeight: on ? FontWeight.w600 : FontWeight.w400),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.s16),
            InkWell(
              onTap: _pickDob,
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Date of birth *',
                    suffixIcon: Icon(Icons.calendar_today, size: 18)),
                child: Text(_dobLabel(),
                    style: TextStyle(
                        color: _dob == null
                            ? AppColors.textDisabled
                            : AppColors.textPrimary)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.s12),
              Text(_error!,
                  style:
                      AppTextStyles.bodySmall.copyWith(color: AppColors.errorRed)),
            ],
            const SizedBox(height: AppSpacing.s20),
            PrimaryButton(
              label: _busy ? 'Saving…' : 'Save',
              loading: _busy,
              onPressed: _busy ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
