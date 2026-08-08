import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/company_model.dart';
import '../../data/models/student_model.dart';
import '../theme/app_theme.dart';

class CompanyModal extends StatelessWidget {
  final CompanyModel company;
  final StudentModel? student;
  final bool isSelected;

  const CompanyModal({
    super.key,
    required this.company,
    this.student,
    required this.isSelected,
  });

  Future<void> _launchUrl(String urlStr) async {
    if (urlStr.isEmpty) return;
    final Uri uri = Uri.parse(urlStr.startsWith('http') ? urlStr : 'https://$urlStr');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedState = isSelected;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header Row
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: selectedState
                          ? [const Color(0xFF059669), const Color(0xFF10B981)]
                          : [AppTheme.primaryGradientStart, AppTheme.primaryGradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    selectedState ? LucideIcons.checkCircle : LucideIcons.building2,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.companyName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(LucideIcons.mapPin, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            company.location,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Status Banner
            if (selectedState)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.award, color: AppTheme.success, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Congratulations! You are Selected',
                            style: TextStyle(
                              color: AppTheme.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Your Registration / NeoPat ID is in the official offer release shortlist.',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // CTC & Stipend Cards
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    title: 'CTC PACKAGE',
                    value: company.ctc,
                    icon: LucideIcons.indianRupee,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    title: 'MONTHLY STIPEND',
                    value: company.stipend,
                    icon: LucideIcons.coins,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Eligibility & Details
            _detailTile(
              icon: LucideIcons.shieldCheck,
              title: 'Eligibility Criteria',
              subtitle: company.eligibility,
            ),
            const SizedBox(height: 12),
            _detailTile(
              icon: LucideIcons.graduationCap,
              title: 'Eligible Branches',
              subtitle: company.branches,
            ),
            const SizedBox(height: 12),
            _detailTile(
              icon: LucideIcons.clock,
              title: 'Registration Deadline',
              subtitle: company.deadline.isNotEmpty ? company.deadline : 'Announced via Email',
            ),
            const SizedBox(height: 12),
            _detailTile(
              icon: LucideIcons.calendar,
              title: 'Campus Visit Date',
              subtitle: company.visitDate.isNotEmpty ? company.visitDate : 'TBA',
            ),
            
            if (company.eventTimeline.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Selection Process Timeline',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ...company.eventTimeline.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == company.eventTimeline.length - 1;

                // Safely extract values
                final title = item['title'] ?? item['stage'] ?? item['name'] ?? 'Stage';
                final date = item['date'] ?? item['time'] ?? item['dateTime'] ?? '';
                final isCompleted = item['status']?.toString().toLowerCase() == 'completed' || item['completed'] == true;
                final isCurrent = item['status']?.toString().toLowerCase() == 'current' || item['status']?.toString().toLowerCase() == 'active';

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? AppTheme.success
                                : isCurrent
                                    ? AppTheme.accent
                                    : AppTheme.textSecondary.withOpacity(0.5),
                            border: Border.all(
                              color: isCurrent ? AppTheme.accent.withOpacity(0.3) : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 40,
                            color: AppTheme.border,
                          )
                        else
                          const SizedBox(height: 40),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.toString(),
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (date.toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              date.toString(),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ],

            const SizedBox(height: 24),

            // Action Links
            if (company.links.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _launchUrl(company.links),
                  icon: const Icon(LucideIcons.externalLink, size: 18),
                  label: const Text('Open Placement Portal / Careers'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _detailTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
