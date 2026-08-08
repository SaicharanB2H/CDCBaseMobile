import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/models/company_model.dart';
import '../../data/models/student_model.dart';
import '../theme/app_theme.dart';

class CompanyCard extends StatelessWidget {
  final CompanyModel company;
  final StudentModel? student;
  final bool isShortlisted;
  final VoidCallback onTap;

  const CompanyCard({
    super.key,
    required this.company,
    this.student,
    required this.isShortlisted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shortlisted = isShortlisted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: shortlisted ? AppTheme.success.withOpacity(0.6) : AppTheme.border,
          width: shortlisted ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: shortlisted
                        ? AppTheme.success.withOpacity(0.15)
                        : AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    shortlisted ? LucideIcons.checkCircle2 : LucideIcons.building2,
                    color: shortlisted ? AppTheme.success : AppTheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Company Name & Visit Date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.companyName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(LucideIcons.calendar, size: 12, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            company.visitDate.isNotEmpty
                                ? 'Visit: ${company.visitDate}'
                                : 'Visit Date: TBA',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // CTC Package & Shortlist Status Pill
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      company.ctc,
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: shortlisted
                            ? AppTheme.success.withOpacity(0.2)
                            : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: shortlisted
                              ? AppTheme.success.withOpacity(0.4)
                              : AppTheme.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            shortlisted ? LucideIcons.award : LucideIcons.userCheck,
                            size: 11,
                            color: shortlisted ? AppTheme.success : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            shortlisted ? 'Shortlisted' : 'Eligible',
                            style: TextStyle(
                              color: shortlisted ? AppTheme.success : AppTheme.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
