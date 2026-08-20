import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/company_model.dart';
import '../../data/models/event_model.dart';
import '../../data/models/student_model.dart';
import '../theme/app_theme.dart';
import 'linkified_text.dart';
import 'package:intl/intl.dart';
class CompanyModal extends StatelessWidget {
  final CompanyModel company;
  final StudentModel? student;
  final bool isSelected;
  final List<EventModel> companyEvents;

  const CompanyModal({
    super.key,
    required this.company,
    this.student,
    required this.isSelected,
    required this.companyEvents,
  });

  Future<void> _launchUrl(String urlStr) async {
    if (urlStr.isEmpty) return;
    final Uri uri = Uri.parse(urlStr.startsWith('http') ? urlStr : 'https://$urlStr');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $urlStr: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedState = isSelected;

    return Material(
      color: AppTheme.background,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
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
                          Expanded(
                            child: Text(
                              company.location,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
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
                  color: AppTheme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
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
              ...company.eventTimeline.entries.toList().asMap().entries.map((entry) {
                final index = entry.key;
                final mapEntry = entry.value;
                final isLast = index == company.eventTimeline.length - 1;

                final dateStr = mapEntry.key;
                final title = mapEntry.value?.toString() ?? 'Stage';

                // Check if the date is past or future
                final eventDate = DateTime.tryParse(dateStr);
                final today = DateTime.now();
                bool isCompleted = false;
                bool isCurrent = false;

                if (eventDate != null) {
                  if (!(eventDate.hour == 0 && eventDate.minute == 0)) {
                    if (eventDate.isBefore(today)) {
                      isCompleted = true;
                    } else if (eventDate.year == today.year && eventDate.month == today.month && eventDate.day == today.day) {
                      isCurrent = true;
                    }
                  } else {
                    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
                    final todayDay = DateTime(today.year, today.month, today.day);
                    if (eventDay.isBefore(todayDay)) {
                      isCompleted = true;
                    } else if (eventDay.isAtSameMomentAs(todayDay)) {
                      isCurrent = true;
                    }
                  }
                }

                // Format the date for display
                String displayDate = dateStr;
                if (eventDate != null) {
                  displayDate = "${eventDate.day.toString().padLeft(2, '0')}/${eventDate.month.toString().padLeft(2, '0')}/${eventDate.year}";
                  
                  // Don't show time if it's exactly 12:00 AM (00:00)
                  if (!(eventDate.hour == 0 && eventDate.minute == 0)) {
                    int h = eventDate.hour;
                    String amPm = h >= 12 ? 'PM' : 'AM';
                    if (h == 0) h = 12;
                    if (h > 12) h -= 12;
                    String m = eventDate.minute.toString().padLeft(2, '0');
                    displayDate += " • $h:$m $amPm";
                  }
                }

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
                                    : AppTheme.textSecondary.withValues(alpha: 0.5),
                            border: Border.all(
                              color: isCurrent ? AppTheme.accent.withValues(alpha: 0.3) : Colors.transparent,
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
                            title,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (displayDate.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              displayDate,
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

            // Company Mails (Events)
            if (companyEvents.isNotEmpty) ...[
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  leading: const Icon(LucideIcons.mail, color: AppTheme.primary),
                  title: Text(
                    'Placement Email Updates (${companyEvents.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  children: (() {
                    final sortedEvents = List<EventModel>.from(companyEvents);
                    sortedEvents.sort((a, b) {
                      final dateA = DateTime.tryParse(a.receivedAt.isNotEmpty ? a.receivedAt : a.eventDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
                      final dateB = DateTime.tryParse(b.receivedAt.isNotEmpty ? b.receivedAt : b.eventDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
                      return dateB.compareTo(dateA);
                    });
                    return sortedEvents.map((evt) {
                      String dateStr = evt.receivedAt.isNotEmpty ? evt.receivedAt : evt.eventDate;
                    try {
                      final parsed = DateTime.parse(dateStr);
                      dateStr = DateFormat('MMM d, yyyy • h:mm a').format(parsed.toLocal());
                    } catch (_) {}

                    bool isEventShortlisted(EventModel e) {
                      if (student == null) return false;
                      final neopat = student!.neopatId.trim().toUpperCase();
                      final regNo = student!.regNo.trim().toUpperCase();
                      return e.shortlistedRegs.any((r) {
                        final reg = r.trim().toUpperCase();
                        return (neopat.isNotEmpty && reg == neopat) || (regNo.isNotEmpty && reg == regNo);
                      });
                    }
                    
                    final isShortlisted = isEventShortlisted(evt);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isShortlisted ? AppTheme.success.withValues(alpha: 0.4) : AppTheme.border),
                      ),
                      child: Material(
                        color: isShortlisted ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.surfaceLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(11),
                        clipBehavior: Clip.antiAlias,
                        child: ExpansionTile(
                        shape: const Border(),
                        title: Text(
                          evt.subject,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            const Icon(LucideIcons.calendar, size: 12, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            if (isShortlisted) ...[
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.success.withValues(alpha: 0.5)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(LucideIcons.checkCircle2, size: 10, color: AppTheme.success),
                                    SizedBox(width: 4),
                                    Text(
                                      'SELECTED',
                                      style: TextStyle(
                                        color: AppTheme.success,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16.0),
                            decoration: const BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LinkifiedText(
                                  text: evt.body.isNotEmpty ? evt.body : 'No content available.',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                  linkStyle: const TextStyle(
                                    color: AppTheme.primary,
                                    decoration: TextDecoration.underline,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                  onLinkTap: _launchUrl,
                                ),
                                if (evt.links.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  const Divider(height: 1, color: AppTheme.border),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Attachments & Links',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...evt.links.map((link) => Padding(
                                        padding: const EdgeInsets.only(bottom: 12.0),
                                        child: GestureDetector(
                                          onTap: () => _launchUrl(link),
                                          child: Text(
                                            link,
                                            style: const TextStyle(
                                              color: AppTheme.primary,
                                              decoration: TextDecoration.underline,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      )),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ), // End of ExpansionTile
                      ), // End of Material
                    );
                    }).toList();
                  })(),
                ),
              ),
            ],
          ],
        ),
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
