import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../widgets/components.dart';

class ServiceLandingScreen extends StatelessWidget {
  final String serviceId;

  const ServiceLandingScreen({super.key, required this.serviceId});

  ServiceInfo get _info => _services[serviceId] ?? _services['corporate']!;

  @override
  Widget build(BuildContext context) {
    final info = _info;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF3EA),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s16,
          AppSpacing.s16,
          112,
        ),
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.go('/home'),
                      child: Container(
                        width: 40,
                        height: 40,
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
                  ],
                ),
                const SizedBox(height: AppSpacing.s12),
                Text(info.title,
                    style: AppTextStyles.h1.copyWith(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpacing.s12),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.r16),
              border: Border.all(color: AppColors.borderDefault),
              boxShadow: AppShadows.shadow1,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.teal50,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Icon(info.icon, color: AppColors.teal700, size: 26),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(info.title, style: AppTextStyles.h3),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        info.subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          for (final item in info.items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s12),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.s12),
                child: Row(
                  children: [
                    Icon(item.icon, color: AppColors.teal700, size: 22),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: AppTextStyles.h4),
                          const SizedBox(height: AppSpacing.s2),
                          Text(
                            item.subtitle,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.s8),
          ElevatedButton.icon(
            onPressed: () => context.push(info.primaryRoute),
            icon: Icon(info.primaryIcon),
            label: Text(info.primaryLabel),
          ),
          const SizedBox(height: AppSpacing.s12),
          OutlinedButton.icon(
            onPressed: () => context.push('/support'),
            icon: const Icon(Icons.support_agent_rounded),
            label: const Text('Talk to support'),
          ),
        ],
      ),
    );
  }
}

class ServiceInfo {
  final String title;
  final String subtitle;
  final IconData icon;
  final String primaryLabel;
  final String primaryRoute;
  final IconData primaryIcon;
  final List<ServiceItem> items;

  const ServiceInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryLabel,
    required this.primaryRoute,
    required this.primaryIcon,
    required this.items,
  });
}

class ServiceItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const ServiceItem(this.title, this.subtitle, this.icon);
}

const _services = {
  'mri': ServiceInfo(
    title: 'MRI & Scans',
    subtitle:
        'Compare nearby scan centres and get help choosing the right scan.',
    icon: Icons.radar_rounded,
    primaryLabel: 'Browse health tests',
    primaryRoute: '/tests',
    primaryIcon: Icons.science_rounded,
    items: [
      ServiceItem(
        'MRI, CT, X-Ray and ultrasound',
        'Availability depends on location.',
        Icons.local_hospital_rounded,
      ),
      ServiceItem(
        'Assisted booking',
        'Support can help confirm preparation and slots.',
        Icons.event_available_rounded,
      ),
      ServiceItem(
        'Reports in app',
        'Upload or receive scan reports in one place.',
        Icons.description_rounded,
      ),
    ],
  ),
  'doctor': ServiceInfo(
    title: 'Doctor Consult',
    subtitle: 'Get guidance before or after booking diagnostics.',
    icon: Icons.medical_services_rounded,
    primaryLabel: 'Book a test first',
    primaryRoute: '/tests',
    primaryIcon: Icons.science_rounded,
    items: [
      ServiceItem(
        'General physician',
        'For symptoms, test selection and follow-up.',
        Icons.medical_services_rounded,
      ),
      ServiceItem(
        'Report review',
        'Understand abnormal values and next steps.',
        Icons.fact_check_rounded,
      ),
      ServiceItem(
        'Family support',
        'Consults for family members from one account.',
        Icons.family_restroom_rounded,
      ),
    ],
  ),
  'diet': ServiceInfo(
    title: 'Diet Consult',
    subtitle: 'Nutrition guidance based on your goals and lab markers.',
    icon: Icons.restaurant_rounded,
    primaryLabel: 'View wellness tests',
    primaryRoute: '/tests',
    primaryIcon: Icons.monitor_heart_rounded,
    items: [
      ServiceItem(
        'Weight and lifestyle plans',
        'Practical food plans for daily routines.',
        Icons.restaurant_menu_rounded,
      ),
      ServiceItem(
        'Diabetes and cholesterol care',
        'Diet support linked to blood markers.',
        Icons.favorite_rounded,
      ),
      ServiceItem(
        'Follow-up reminders',
        'Track retests and progress over time.',
        Icons.notifications_active_rounded,
      ),
    ],
  ),
  'vaccination': ServiceInfo(
    title: 'Vaccination',
    subtitle: 'Adult and family vaccination support with assisted scheduling.',
    icon: Icons.vaccines_rounded,
    primaryLabel: 'Check preventive tests',
    primaryRoute: '/tests',
    primaryIcon: Icons.health_and_safety_rounded,
    items: [
      ServiceItem(
        'Family vaccine planning',
        'Keep track of recommended vaccine windows.',
        Icons.family_restroom_rounded,
      ),
      ServiceItem(
        'Home or centre options',
        'Availability depends on city and vaccine type.',
        Icons.home_work_rounded,
      ),
      ServiceItem(
        'Digital records',
        'Keep vaccination records with your health profile.',
        Icons.verified_rounded,
      ),
    ],
  ),
  'corporate': ServiceInfo(
    title: 'Corporate Health',
    subtitle: 'Employee health packages, camps and reports for organizations.',
    icon: Icons.business_rounded,
    primaryLabel: 'Explore packages',
    primaryRoute: '/packages',
    primaryIcon: Icons.inventory_2_rounded,
    items: [
      ServiceItem(
        'Bulk health checkups',
        'Custom packages for teams and workplaces.',
        Icons.groups_rounded,
      ),
      ServiceItem(
        'On-site camps',
        'Sample collection at office locations.',
        Icons.location_city_rounded,
      ),
      ServiceItem(
        'Admin reporting',
        'Centralized status and report coordination.',
        Icons.analytics_rounded,
      ),
    ],
  ),
};
