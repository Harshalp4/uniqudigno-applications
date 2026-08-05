import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';

import '../../providers/account_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/pressable.dart';

/// Family members — warm redesign (profile wireframe 4): emoji avatar cards
/// with relationship + age, per-member shortcuts, the family-discount nudge,
/// and a dashed add-member button. Diagnostics need age + sex to interpret
/// results, so those stay required in the add sheet.
class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  static const _canvas = Color(0xFFFAF3EA);

  void _openAddSheet(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const _AddFamilySheet(),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final family = ref.watch(familyProvider);
    final me =
        ref.watch(meProvider).maybeWhen(data: (m) => m, orElse: () => null);

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, 0),
              child: Row(
                children: [
                  Pressable(
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go('/home'),
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 10,
                              offset: Offset(0, 3)),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          size: 20, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Text('My Family',
                      style: AppTextStyles.h2.copyWith(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8EF),
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  border:
                      Border.all(color: const Color(0xFFBFE8CC), width: 1.4),
                ),
                child: Text(
                    '👨‍👩‍👧 Book for 2+ members together — save up to 25% each',
                    style: AppTextStyles.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F7A42))),
              ),
            ),
            Expanded(
              child: family.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) =>
                    const Center(child: Text('Could not load family.')),
                data: (list) => ListView(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  children: [
                    // Self card
                    _MemberCard(
                      emoji: '👤',
                      bg: const Color(0xFFCDEAEA),
                      name: (me?.name?.trim().isNotEmpty ?? false)
                          ? me!.name!
                          : 'You',
                      detail: [
                        'Self',
                        if ((me?.gender ?? '').isNotEmpty) me!.gender!,
                        if (me?.age != null) '${me!.age} yrs',
                      ].join(' · '),
                      badge: 'YOU',
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    for (final m in list) ...[
                      _MemberCard(
                        emoji: (m.gender ?? '').toLowerCase() == 'female'
                            ? '👩'
                            : '👨',
                        bg: const Color(0xFFF8DCD4),
                        name: m.name,
                        detail: m.summary,
                        onBook: () => context.push('/blood-tests'),
                        onReports: () => context.push('/reports'),
                        onDelete: () =>
                            ref.read(familyProvider.notifier).remove(m.id),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                    ],
                    Pressable(
                      onTap: () => _openAddSheet(context),
                      child: Container(
                        margin: const EdgeInsets.only(top: AppSpacing.s4),
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.s12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFFB9C6D2), width: 1.8),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text('+ Add family member',
                            style: AppTextStyles.captionMed.copyWith(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF3E7FBE))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final String emoji;
  final Color bg;
  final String name;
  final String detail;
  final String? badge;
  final VoidCallback? onBook;
  final VoidCallback? onReports;
  final VoidCallback? onDelete;
  const _MemberCard({
    required this.emoji,
    required this.bg,
    required this.name,
    required this.detail,
    this.badge,
    this.onBook,
    this.onReports,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration:
                      BoxDecoration(color: bg, shape: BoxShape.circle),
                  child:
                      Text(emoji, style: const TextStyle(fontSize: 19)),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.h4
                              .copyWith(fontWeight: FontWeight.w800)),
                      Text(detail,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDF4FB),
                      borderRadius: BorderRadius.circular(AppRadius.r100),
                    ),
                    child: Text(badge!,
                        style: AppTextStyles.caption.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2C5F94))),
                  )
                else if (onDelete != null)
                  Pressable(
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.all(AppSpacing.s4),
                      child: Icon(Icons.delete_outline,
                          size: 19, color: AppColors.textDisabled),
                    ),
                  ),
              ],
            ),
          ),
          if (onBook != null || onReports != null) ...[
            const Divider(height: 1, color: Color(0xFFF3EDE2)),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s8),
              child: Row(
                children: [
                  if (onBook != null)
                    Expanded(
                      child: Pressable(
                        onTap: onBook,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F1E6),
                            borderRadius:
                                BorderRadius.circular(AppRadius.r100),
                          ),
                          child: Text('🧪 Book a test',
                              style: AppTextStyles.caption.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  if (onBook != null && onReports != null)
                    const SizedBox(width: AppSpacing.s8),
                  if (onReports != null)
                    Expanded(
                      child: Pressable(
                        onTap: onReports,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F1E6),
                            borderRadius:
                                BorderRadius.circular(AppRadius.r100),
                          ),
                          child: Text('📄 Reports',
                              style: AppTextStyles.caption.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddFamilySheet extends ConsumerStatefulWidget {
  const _AddFamilySheet();

  @override
  ConsumerState<_AddFamilySheet> createState() => _AddFamilySheetState();
}

class _AddFamilySheetState extends ConsumerState<_AddFamilySheet> {
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  String? _relationship;
  String? _gender; // Male | Female | Other
  DateTime? _dob;
  String _blood = 'Unknown';
  bool _busy = false;
  String? _error;

  static const _relationships = [
    'Spouse', 'Son', 'Daughter', 'Father', 'Mother', 'Brother', 'Sister', 'Other'
  ];
  // display → BloodGroup enum name
  static const _bloodGroups = <String, String>{
    "Don't know": 'Unknown',
    'A+': 'APositive', 'A-': 'ANegative',
    'B+': 'BPositive', 'B-': 'BNegative',
    'AB+': 'ABPositive', 'AB-': 'ABNegative',
    'O+': 'OPositive', 'O-': 'ONegative',
  };

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: 'Date of birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      return setState(() => _error = 'Enter a name.');
    }
    if (_relationship == null) {
      return setState(() => _error = 'Select the relationship.');
    }
    if (_gender == null) return setState(() => _error = 'Select gender.');
    if (_dob == null) return setState(() => _error = 'Select date of birth.');

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final d = _dob!;
      await ref.read(familyProvider.notifier).add({
        'name': _name.text.trim(),
        'relationship': _relationship,
        'gender': _gender,
        'dateOfBirth':
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        'bloodGroup': _blood,
        if (_mobile.text.trim().isNotEmpty) 'mobile': _mobile.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          final msg = DioClient.errorMessage(e);
          _error = msg.contains('401') || msg.toLowerCase().contains('unauth')
              ? 'Please log in again to add a family member.'
              : 'Could not add member: $msg';
        });
      }
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
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Add family member', style: AppTextStyles.h2),
            const SizedBox(height: 4),
            Text(
                'This person is a patient — age and sex are needed to read lab results.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.s20),
            TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name *')),
            const SizedBox(height: AppSpacing.s12),
            DropdownButtonFormField<String>(
              initialValue: _relationship,
              decoration: const InputDecoration(labelText: 'Relationship *'),
              items: _relationships
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _relationship = v),
            ),
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
            const SizedBox(height: AppSpacing.s16),
            DropdownButtonFormField<String>(
              initialValue: 'Unknown',
              decoration:
                  const InputDecoration(labelText: 'Blood group (optional)'),
              items: _bloodGroups.entries
                  .map((e) => DropdownMenuItem(value: e.value, child: Text(e.key)))
                  .toList(),
              onChanged: (v) => setState(() => _blood = v ?? 'Unknown'),
            ),
            const SizedBox(height: AppSpacing.s12),
            TextField(
                controller: _mobile,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Mobile (optional)', prefixText: '+91  ')),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.s12),
              Text(_error!,
                  style:
                      AppTextStyles.bodySmall.copyWith(color: AppColors.errorRed)),
            ],
            const SizedBox(height: AppSpacing.s20),
            PrimaryButton(
              label: _busy ? 'Adding…' : 'Add member',
              loading: _busy,
              onPressed: _busy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
