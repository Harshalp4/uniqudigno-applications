import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/catalogue_models.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalogue_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/cart_snackbar.dart';
import '../../widgets/warm_scaffold.dart';

/// Custom Package Builder (Section 8 / /packages/custom/builder).
/// Multi-select tests with a live, tiered discount. Thresholds mirror the
/// custom_package_discount_* app_config keys (server is the source of truth).
class CustomPackageBuilderScreen extends ConsumerStatefulWidget {
  const CustomPackageBuilderScreen({super.key});

  @override
  ConsumerState<CustomPackageBuilderScreen> createState() =>
      _CustomPackageBuilderScreenState();
}

class _CustomPackageBuilderScreenState
    extends ConsumerState<CustomPackageBuilderScreen> {
  final _selected = <String, Test>{};
  String _query = '';

  /// Tiered discount by test count (defaults; configurable server-side).
  int get _discountPercent {
    final n = _selected.length;
    if (n >= 8) return 25;
    if (n >= 5) return 15;
    if (n >= 3) return 10;
    return 0;
  }

  num get _mrp => _selected.values.fold<num>(0, (s, t) => s + t.price);
  num get _price => (_mrp * (100 - _discountPercent) / 100).round();

  @override
  Widget build(BuildContext context) {
    final tests = ref.watch(testsProvider(_query.isEmpty ? null : _query));

    return WarmScaffold(
      title: 'Build Your Package',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search tests to add',
                prefixIcon: Icon(Icons.search, color: AppColors.textDisabled),
              ),
            ),
          ),
          _TierHint(count: _selected.length, percent: _discountPercent),
          Expanded(
            child: tests.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(child: Text('Could not load tests.')),
              data: (list) => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final t = list[i];
                  final on = _selected.containsKey(t.id);
                  return CheckboxListTile(
                    value: on,
                    onChanged: (_) => setState(() {
                      if (on) {
                        _selected.remove(t.id);
                      } else {
                        _selected[t.id] = t;
                      }
                    }),
                    activeColor: AppColors.teal700,
                    title: Text(t.name, style: AppTextStyles.h4),
                    subtitle: Text('₹${t.price} · ${t.parameterCount} parameters',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selected.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.borderDefault)),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(children: [
                          Text('₹$_price', style: AppTextStyles.priceLarge),
                          if (_discountPercent > 0) ...[
                            const SizedBox(width: AppSpacing.s8),
                            Text('₹$_mrp',
                                style: AppTextStyles.priceStrikethrough),
                          ],
                        ]),
                        Text('${_selected.length} tests selected',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 150,
                      child: PrimaryButton(label: 'Add to Cart', onPressed: _addAll),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _addAll() async {
    final notifier = ref.read(cartProvider.notifier);
    String? error;
    for (final t in _selected.values) {
      error = await notifier.addTest(
          id: t.id, name: t.name, mrp: t.mrp, price: t.price);
      if (error != null) break;
    }
    if (!mounted) return;
    if (error != null) {
      showAppSnackBar(context, error);
    } else {
      setState(_selected.clear);
    }
  }
}

class _TierHint extends StatelessWidget {
  final int count;
  final int percent;
  const _TierHint({required this.count, required this.percent});

  @override
  Widget build(BuildContext context) {
    final next = count < 3 ? 3 : (count < 5 ? 5 : (count < 8 ? 8 : null));
    final text = percent > 0
        ? '$percent% off applied · ${next != null ? 'add ${next - count} more for a bigger discount' : 'maximum discount unlocked'}'
        : 'Add ${3 - count} more tests to unlock 10% off';
    return Container(
      width: double.infinity,
      color: AppColors.teal50,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
      child: Text(text,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.teal800)),
    );
  }
}
