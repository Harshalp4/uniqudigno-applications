import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/account_provider.dart';
import '../../widgets/pressable.dart';

/// Saved addresses — warm redesign (profile wireframe 5): type-icon cards
/// with DEFAULT badge, set-default / delete actions, dashed add-new.
class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  static const _canvas = Color(0xFFFAF3EA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressProvider);

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
                  Text('My Addresses',
                      style: AppTextStyles.h2.copyWith(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Expanded(
              child: addresses.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Center(
                    child: Text('Could not load addresses.')),
                data: (list) => ListView(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  children: [
                    for (final a in list) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.s12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x0D000000),
                                blurRadius: 12,
                                offset: Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDF4FB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                  a.type.toLowerCase() == 'home'
                                      ? '🏠'
                                      : '🏢',
                                  style: const TextStyle(fontSize: 17)),
                            ),
                            const SizedBox(width: AppSpacing.s12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(a.type,
                                          style: AppTextStyles.h4.copyWith(
                                              fontWeight: FontWeight.w800)),
                                      if (a.isDefault) ...[
                                        const SizedBox(
                                            width: AppSpacing.s8),
                                        Container(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color:
                                                const Color(0xFFE9F8EE),
                                            borderRadius:
                                                BorderRadius.circular(
                                                    AppRadius.r100),
                                          ),
                                          child: Text('DEFAULT',
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                      fontSize: 8.5,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: const Color(
                                                          0xFF2A9C54))),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(a.fullLine,
                                      style: AppTextStyles.caption
                                          .copyWith(
                                              color: AppColors
                                                  .textSecondary,
                                              height: 1.35)),
                                  if (!a.isDefault)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: AppSpacing.s8),
                                      child: Pressable(
                                        onTap: () => ref
                                            .read(
                                                addressProvider.notifier)
                                            .setDefault(a.id),
                                        child: Text('Set as default',
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w800,
                                                    color: const Color(
                                                        0xFF3E7FBE))),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Pressable(
                              onTap: () => ref
                                  .read(addressProvider.notifier)
                                  .remove(a.id),
                              child: const Padding(
                                padding: EdgeInsets.all(AppSpacing.s4),
                                child: Icon(Icons.delete_outline,
                                    size: 19,
                                    color: AppColors.textDisabled),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                    ],
                    Pressable(
                      onTap: () => context.push('/addresses/add'),
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
                        child: Text('+ Add a new address',
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
