import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
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

    String getDisplayVisitDate() {
      final todayDate = DateTime.now();
      DateTime? nextUpcomingDate;
      String nextUpcomingDesc = '';

      if (company.eventTimeline.isNotEmpty) {
        for (final entry in company.eventTimeline.entries) {
          final eventDate = DateTime.tryParse(entry.key.trim());
          if (eventDate != null) {
            final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
            final todayDay = DateTime(todayDate.year, todayDate.month, todayDate.day);
            
            if (!eventDay.isBefore(todayDay)) {
              if (nextUpcomingDate == null || eventDate.isBefore(nextUpcomingDate)) {
                nextUpcomingDate = eventDate;
                nextUpcomingDesc = entry.value?.toString() ?? 'Upcoming';
              }
            }
          }
        }
      }

      if (nextUpcomingDate != null) {
        final formatter = DateFormat('MMM d');
        String timeStr = '';
        // check if has specific time
        if (nextUpcomingDate.hour != 0 || nextUpcomingDate.minute != 0) {
           timeStr = DateFormat(' • h:mm a').format(nextUpcomingDate);
        }
        return 'Next: $nextUpcomingDesc • ${formatter.format(nextUpcomingDate)}$timeStr';
      }

      return company.visitDate.isNotEmpty ? 'Visit: ${company.visitDate}' : 'Visit Date: TBA';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: shortlisted ? AppTheme.success.withValues(alpha: 0.6) : AppTheme.border,
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
                        ? AppTheme.success.withValues(alpha: 0.15)
                        : AppTheme.primary.withValues(alpha: 0.15),
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
                          Expanded(
                            child: Text(
                              getDisplayVisitDate(),
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                    Container(
                      constraints: const BoxConstraints(maxWidth: 100),
                      alignment: Alignment.centerRight,
                      child: Text(
                        company.ctc,
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (company.selected || shortlisted) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: company.selected 
                              ? AppTheme.textSecondary.withValues(alpha: 0.1)
                              : (shortlisted ? AppTheme.success.withValues(alpha: 0.2) : AppTheme.surfaceLight),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: company.selected
                                ? AppTheme.textSecondary.withValues(alpha: 0.3)
                                : (shortlisted ? AppTheme.success.withValues(alpha: 0.4) : AppTheme.border),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              company.selected
                                  ? LucideIcons.checkSquare
                                  : (shortlisted ? LucideIcons.award : LucideIcons.userCheck),
                              size: 11,
                              color: company.selected 
                                  ? AppTheme.textSecondary 
                                  : (shortlisted ? AppTheme.success : AppTheme.textSecondary),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              company.selected ? 'Completed' : (shortlisted ? 'Shortlisted' : 'Eligible'),
                              style: TextStyle(
                                color: company.selected 
                                    ? AppTheme.textSecondary 
                                    : (shortlisted ? AppTheme.success : AppTheme.textSecondary),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
