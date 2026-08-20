import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/event_model.dart';
import '../../data/models/student_model.dart';
import '../theme/app_theme.dart';

class TodayAgendaWidget extends StatelessWidget {
  final List<EventModel> events;
  final StudentModel? student;

  const TodayAgendaWidget({
    super.key,
    required this.events,
    this.student,
  });

  bool isShortlisted(EventModel event) {
    if (student == null || student!.neopatId.isEmpty) return false;
    final neopat = student!.neopatId.trim().toUpperCase();
    return event.shortlistedRegs.any((r) => r.trim().toUpperCase() == neopat);
  }

  Future<void> _launchUrl(String urlStr) async {
    if (urlStr.isEmpty) return;
    final Uri uri = Uri.parse(urlStr.startsWith('http') ? urlStr : 'https://$urlStr');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Row(
          children: [
            Icon(LucideIcons.calendarCheck, color: AppTheme.textSecondary),
            SizedBox(width: 12),
            Text(
              'No announcements or drives scheduled for today.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.bell, size: 18, color: AppTheme.accent),
              SizedBox(width: 8),
              Text(
                'Recent Placement Announcements',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: events.length > 3 ? 3 : events.length,
            separatorBuilder: (context, index) => const Divider(color: AppTheme.border, height: 16),
            itemBuilder: (context, index) {
              final event = events[index];
              final shortlisted = isShortlisted(event);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: shortlisted
                              ? AppTheme.success.withValues(alpha: 0.2)
                              : AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          event.companyName,
                          style: TextStyle(
                            color: shortlisted ? AppTheme.success : AppTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.eventDate,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.subject,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.body,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (event.links.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _launchUrl(event.links.first),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.link, size: 12, color: AppTheme.accent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.links.first,
                              style: const TextStyle(
                                color: AppTheme.accent,
                                fontSize: 11,
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
