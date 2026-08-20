import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../data/models/company_model.dart';
import '../../data/models/event_model.dart';
import '../../data/models/student_model.dart';
import '../../data/models/unified_calendar_event.dart';
import '../theme/app_theme.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/linkified_text.dart';
class EventsScreen extends StatefulWidget {
  final StudentModel? student;
  final List<EventModel> events;
  final List<CompanyModel> companies;
  final ScrollController? scrollController;

  const EventsScreen({
    super.key,
    required this.student,
    required this.events,
    required this.companies,
    this.scrollController,
  });

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final TextEditingController _feedSearchController = TextEditingController();
  DateTime _selectedCalendarDate = DateTime.now();
  String activeView = 'CALENDAR'; // FEED, CALENDAR
  String activeFeedTab = 'ALL';
  String feedSearchQuery = '';

  @override
  void dispose() {
    _feedSearchController.dispose();
    super.dispose();
  }

  bool _isStudentShortlisted(EventModel event) {
    if (widget.student == null || widget.student!.neopatId.isEmpty) return false;
    final neopat = widget.student!.neopatId.trim().toUpperCase();
    return event.shortlistedRegs.any((r) => r.trim().toUpperCase() == neopat);
  }

  Future<void> _launchUrl(String urlStr) async {
    if (urlStr.isEmpty) return;
    final Uri uri = Uri.parse(urlStr.startsWith('http') ? urlStr : 'https://$urlStr');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $urlStr: $e');
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy • h:mm a').format(date.toLocal());
    } catch (_) {
      return dateStr;
    }
  }

  List<UnifiedCalendarEvent> _getUnifiedEvents() {
    // 1. Sort events chronologically
    final sortedEvents = List<EventModel>.from(widget.events)..sort((a, b) {
      final timeA = DateTime.tryParse(a.createdAt)?.millisecondsSinceEpoch ?? 0;
      final timeB = DateTime.tryParse(b.createdAt)?.millisecondsSinceEpoch ?? 0;
      if (timeA != timeB) return timeA - timeB;
      return a.id.compareTo(b.id);
    });

    final dedupeMap = <String, EventModel>{};

    for (final evt in sortedEvents) {
      // Ignore exactly 12:00 AM events as per constraint
      final rawDateTime = evt.scheduledDateTime.replaceAll('T', ' ').trim();
      if (rawDateTime.isEmpty) continue;

      if (rawDateTime.contains('00:00:00') || rawDateTime.contains('12:00:00 AM') || rawDateTime.contains('12:00 AM')) {
        // Just skip if it matches the 12AM constraint perfectly, though simple check is fine
        final dt = DateTime.tryParse(evt.scheduledDateTime);
        if (dt != null && dt.hour == 0 && dt.minute == 0) {
          continue;
        }
      }

      final compKey = evt.companyName.trim().toLowerCase();
      final parts = rawDateTime.split(' ');
      final dateStr = parts.isNotEmpty ? parts[0] : '';
      final timeStr = parts.length > 1 ? parts.sublist(1).join(' ').trim().toLowerCase() : '';

      final dedupeKey = "${compKey}___${dateStr}___$timeStr";
      final isShortlisted = _isStudentShortlisted(evt);

      if (!dedupeMap.containsKey(dedupeKey)) {
        dedupeMap[dedupeKey] = evt;
      } else {
        final existingEvt = dedupeMap[dedupeKey]!;
        final existingShortlisted = _isStudentShortlisted(existingEvt);

        if (!isShortlisted && existingShortlisted) {
          // Inherit shortlist regs
          dedupeMap[dedupeKey] = EventModel(
            id: evt.id,
            companyName: evt.companyName,
            subject: evt.subject,
            eventDate: evt.eventDate,
            body: evt.body,
            links: evt.links,
            shortlistedRegs: existingEvt.shortlistedRegs, // Inherited
            createdAt: evt.createdAt,
            scheduledDateTime: evt.scheduledDateTime,
            receivedAt: evt.receivedAt,
          );
        } else {
          dedupeMap[dedupeKey] = evt;
        }
      }
    }

    final unifiedEvents = <UnifiedCalendarEvent>[];
    
    // Add emails
    for (final evt in dedupeMap.values) {
      final isShortlisted = _isStudentShortlisted(evt);
      String dStr = evt.eventDate.isNotEmpty ? evt.eventDate : evt.receivedAt.split('T')[0];
      final dt = DateTime.tryParse(dStr);
      if (dt != null) {
        dStr = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
      }
      String? emailTimeStr;
      DateTime? emailParsedDate;
      if (evt.scheduledDateTime.isNotEmpty) {
        final st = DateTime.tryParse(evt.scheduledDateTime.trim());
        if (st != null) {
          emailParsedDate = st;
          final rawSt = evt.scheduledDateTime.trim();
          final timePart = rawSt.contains('T') ? rawSt.split('T').last : (rawSt.contains(' ') ? rawSt.split(' ').last : '');
          if (timePart.isNotEmpty && !timePart.startsWith('00:00:00')) {
            emailTimeStr = DateFormat('h:mm a').format(st);
          }
        }
      }

      unifiedEvents.add(UnifiedCalendarEvent(
        id: evt.id.toString(),
        companyName: evt.companyName,
        dateStr: dStr,
        subject: evt.subject,
        type: isShortlisted ? UnifiedEventType.shortlist : UnifiedEventType.mailScheduled,
        rawEvent: evt,
        displayTime: emailTimeStr,
        parsedDate: emailParsedDate,
      ));
    }

    // Inject timeline events
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (final comp in widget.companies) {
      final compKey = comp.companyName.trim().toLowerCase();
      for (final entry in comp.eventTimeline.entries) {
        final dateKey = entry.key;
        final eventDesc = entry.value?.toString() ?? 'Timeline Event';

        final eventDate = DateTime.tryParse(dateKey.trim());
        if (eventDate == null) continue;
        final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
        
        final normalizedDateStr = "${eventDate.year}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}";

        String? parsedTime;
        final rawKey = dateKey.trim();
        final timePart = rawKey.contains('T') ? rawKey.split('T').last : (rawKey.contains(' ') ? rawKey.split(' ').last : '');
        if (timePart.isNotEmpty && !timePart.startsWith('00:00:00')) {
          parsedTime = DateFormat('h:mm a').format(eventDate);
        }

        // Skip past timeline events
        if (eventDay.isBefore(todayDate)) continue;

        // Check if an email event already exists for this company on this date
        bool matchesExisting = false;
        for (final ue in unifiedEvents) {
          if (ue.companyName.trim().toLowerCase() == compKey && ue.dateStr == normalizedDateStr) {
            matchesExisting = true;
            break;
          }
        }

        if (!matchesExisting) {
          unifiedEvents.add(UnifiedCalendarEvent(
            id: "timeline-${comp.companyName}-$normalizedDateStr",
            companyName: comp.companyName,
            dateStr: normalizedDateStr,
            subject: eventDesc,
            type: UnifiedEventType.upcoming,
            rawEvent: null,
            displayTime: parsedTime,
            parsedDate: eventDate,
          ));
        }
      }
    }

    unifiedEvents.sort((a, b) {
      // 1. Sort by type: shortlist < mailScheduled < upcoming
      // Note: UnifiedEventType enum is ordered as shortlist, mailScheduled, upcoming
      final typeCmp = a.type.index.compareTo(b.type.index);
      if (typeCmp != 0) return typeCmp;

      // 2. Sort chronologically by parsedDate
      final timeA = a.parsedDate?.millisecondsSinceEpoch ?? 0;
      final timeB = b.parsedDate?.millisecondsSinceEpoch ?? 0;
      return timeA.compareTo(timeB);
    });

    return unifiedEvents;
  }

  @override
  Widget build(BuildContext context) {
    // Sort all events by receivedAt (newest first)
    final sortedEvents = List<EventModel>.from(widget.events)..sort((a, b) {
      final timeA = DateTime.tryParse(a.receivedAt)?.millisecondsSinceEpoch ?? 0;
      final timeB = DateTime.tryParse(b.receivedAt)?.millisecondsSinceEpoch ?? 0;
      return timeB.compareTo(timeA);
    });
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          title: Text(
            'Email Events Log',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        body: Column(
          children: [
            // View Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildToggleBtn(
                      'CALENDAR',
                      'Calendar View',
                      LucideIcons.calendarDays,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildToggleBtn(
                      'FEED',
                      'Timeline Feed',
                      LucideIcons.list,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Content
            Expanded(
              child: activeView == 'FEED'
                  ? _buildFeedView(sortedEvents)
                  : _buildCalendarView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleBtn(String viewKey, String label, IconData icon) {
    final isSelected = activeView == viewKey;
    return GestureDetector(
      onTap: () => setState(() => activeView = viewKey),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showEventDetails(EventModel event, bool isShortlisted) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.subject,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(LucideIcons.building2, size: 16, color: AppTheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            event.companyName,
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(LucideIcons.clock, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(event.receivedAt.isNotEmpty ? event.receivedAt : event.eventDate),
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                      if (isShortlisted) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(LucideIcons.checkCircle2, color: AppTheme.success, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Congratulations! You are shortlisted for this event.',
                                  style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const Divider(color: AppTheme.border),
                      const SizedBox(height: 16),
                      LinkifiedText(
                        text: event.body,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.6),
                        linkStyle: const TextStyle(color: AppTheme.primary, decoration: TextDecoration.underline, fontSize: 14, height: 1.6),
                        onLinkTap: _launchUrl,
                      ),
                      if (event.links.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text('Attachments & Links', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary, fontSize: 12)),
                        const SizedBox(height: 12),
                        ...event.links.map((link) {
                          return Padding(
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
                          );
                        }),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeedView(List<EventModel> sortedEvents) {
    final allCount = sortedEvents.length;
    final shortlistedCount = sortedEvents.where((e) => _isStudentShortlisted(e)).length;

    final query = feedSearchQuery.trim().toLowerCase();
    
    final filteredEvents = sortedEvents.where((e) {
      if (activeFeedTab == 'SHORTLISTED' && !_isStudentShortlisted(e)) {
        return false;
      }
      
      if (query.isNotEmpty) {
        final match = e.companyName.toLowerCase().contains(query) ||
                      e.subject.toLowerCase().contains(query) ||
                      e.body.toLowerCase().contains(query);
        if (!match) return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: _feedSearchController,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (val) => setState(() => feedSearchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search events, companies, keywords...',
              prefixIcon: const Icon(LucideIcons.search, color: AppTheme.textSecondary),
              suffixIcon: feedSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, color: AppTheme.textSecondary, size: 18),
                      onPressed: () {
                        _feedSearchController.clear();
                        setState(() => feedSearchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primary),
              ),
            ),
          ),
        ),
        
        // Tabs
        Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => activeFeedTab = 'ALL'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: activeFeedTab == 'ALL' ? AppTheme.primary.withValues(alpha: 0.15) : AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: activeFeedTab == 'ALL' ? AppTheme.primary : AppTheme.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'All Events ($allCount)',
                      style: TextStyle(
                        color: activeFeedTab == 'ALL' ? AppTheme.primary : AppTheme.textSecondary,
                        fontWeight: activeFeedTab == 'ALL' ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => activeFeedTab = 'SHORTLISTED'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: activeFeedTab == 'SHORTLISTED' ? AppTheme.success.withValues(alpha: 0.15) : AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: activeFeedTab == 'SHORTLISTED' ? AppTheme.success : AppTheme.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'My Shortlists ($shortlistedCount)',
                      style: TextStyle(
                        color: activeFeedTab == 'SHORTLISTED' ? AppTheme.success : AppTheme.textSecondary,
                        fontWeight: activeFeedTab == 'SHORTLISTED' ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: filteredEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.mail, size: 48, color: AppTheme.textSecondary),
                      const SizedBox(height: 16),
                      Text(
                        activeFeedTab == 'SHORTLISTED'
                            ? 'No shortlisted events found.'
                            : 'No placement email events found.',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    final isShortlisted = _isStudentShortlisted(event);
                    final dateStr = event.receivedAt.isNotEmpty ? event.receivedAt : event.eventDate;

                    return GestureDetector(
                      onTap: () => _showEventDetails(event, isShortlisted),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isShortlisted ? AppTheme.success.withValues(alpha: 0.05) : AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isShortlisted ? AppTheme.success.withValues(alpha: 0.3) : AppTheme.border,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(LucideIcons.building2, color: AppTheme.primary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.companyName,
                                        style: const TextStyle(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(LucideIcons.clock, size: 12, color: AppTheme.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(dateStr),
                                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (isShortlisted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.success.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(LucideIcons.checkCircle2, size: 10, color: AppTheme.success),
                                        SizedBox(width: 4),
                                        Text(
                                          'SHORTLISTED',
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
                            ),
                            const SizedBox(height: 12),
                            Text(
                              event.subject,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinkifiedText(
                              text: event.body,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                              linkStyle: const TextStyle(color: AppTheme.primary, decoration: TextDecoration.underline, fontSize: 13, height: 1.4),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              onLinkTap: _launchUrl,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCalendarView() {
    final dateStr =
        "${_selectedCalendarDate.year}-${_selectedCalendarDate.month.toString().padLeft(2, '0')}-${_selectedCalendarDate.day.toString().padLeft(2, '0')}";
    
    final unifiedEvents = _getUnifiedEvents();
    
    final dayEvents = unifiedEvents.where((e) => e.dateStr == dateStr).toList();
    
    // Sort day events by priority (Shortlist, Mail Scheduled, Upcoming)
    dayEvents.sort((a, b) => a.type.index.compareTo(b.type.index));

    final hasItems = dayEvents.isNotEmpty;

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CalendarWidget(
            unifiedEvents: unifiedEvents,
            onDaySelected: (day) {
              setState(() {
                _selectedCalendarDate = day;
              });
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Agenda for ${_selectedCalendarDate.day}/${_selectedCalendarDate.month}/${_selectedCalendarDate.year}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (!hasItems)
            const Text(
              'No scheduled events or drives on this date.',
              style: TextStyle(color: AppTheme.textSecondary),
            )
          else
            ...dayEvents.map((ev) {
              if (ev.type == UnifiedEventType.upcoming) {
                // Timeline events have no popup box
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(LucideIcons.calendarClock, color: AppTheme.warning, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ev.companyName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ev.subject,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            if (ev.displayTime != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(LucideIcons.clock, size: 12, color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    ev.displayTime!,
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // Email events
                final isShortlisted = ev.type == UnifiedEventType.shortlist;
                return GestureDetector(
                  onTap: () {
                    if (ev.rawEvent != null) {
                      _showEventDetails(ev.rawEvent!, isShortlisted);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.mail, color: isShortlisted ? AppTheme.success : AppTheme.primary, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ev.subject,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Email: ${ev.companyName}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                              if (ev.displayTime != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(LucideIcons.clock, size: 12, color: AppTheme.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      ev.displayTime!,
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }),
        ],
      ),
    );
  }
}
