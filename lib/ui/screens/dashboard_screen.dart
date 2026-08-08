import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/models/company_model.dart';
import '../../data/models/event_model.dart';
import '../../data/models/student_model.dart';
import '../theme/app_theme.dart';
import '../widgets/company_card.dart';
import '../widgets/company_modal.dart';

class DashboardScreen extends StatefulWidget {
  final StudentModel? student;
  final List<CompanyModel> companies;
  final List<EventModel> events;
  final Future<void> Function() onRefresh;

  const DashboardScreen({
    super.key,
    required this.student,
    required this.companies,
    required this.events,
    required this.onRefresh,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String searchQuery = '';
  String activeFilter = 'ALL'; // ALL, SHORTLISTED, NEOPAT
  bool _isSyncing = false;

  Future<void> _handleSync() async {
    setState(() {
      _isSyncing = true;
    });
    try {
      await widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(LucideIcons.checkCircle2, color: AppTheme.success, size: 20),
                SizedBox(width: 10),
                Text('Database synced successfully!'),
              ],
            ),
            backgroundColor: AppTheme.surface,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.alertTriangle, color: Colors.red, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Sync failed: $e')),
              ],
            ),
            backgroundColor: AppTheme.surface,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  bool _isStudentShortlistedForCompany(CompanyModel company) {
    if (widget.student == null || widget.student!.neopatId.isEmpty) return false;
    final studentNeopat = widget.student!.neopatId.trim().toUpperCase();

    return widget.events.any((e) =>
        e.companyName.trim().toUpperCase() == company.companyName.trim().toUpperCase() &&
        e.shortlistedRegs.any((r) => r.trim().toUpperCase() == studentNeopat));
  }

  List<CompanyModel> get filteredCompanies {
    final query = searchQuery.trim().toLowerCase();
    final neopat = widget.student?.neopatId.toUpperCase() ?? '';

    final list = widget.companies.where((c) {
      final matchesQuery = query.isEmpty ||
          c.companyName.toLowerCase().contains(query) ||
          c.branches.toLowerCase().contains(query) ||
          c.location.toLowerCase().contains(query);

      if (!matchesQuery) return false;

      final isShortlisted = _isStudentShortlistedForCompany(c);
      final isNeopatMatch = neopat.isNotEmpty &&
          c.selectedReg.any((r) => r.toUpperCase() == neopat);

      if (activeFilter == 'SHORTLISTED') return isShortlisted;
      if (activeFilter == 'NEOPAT') return isNeopatMatch;
      return true;
    }).toList();

    list.sort((a, b) {
      final aDate = DateTime.tryParse(a.receivedAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse(b.receivedAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return list;
  }

  int get shortlistedCount {
    return widget.companies.where((c) => _isStudentShortlistedForCompany(c)).length;
  }

  int get neopatMatchedCount {
    if (widget.student == null || widget.student!.neopatId.isEmpty) return 0;
    final neopat = widget.student!.neopatId.toUpperCase();

    return widget.companies.where((c) {
      return c.selectedReg.any((r) => r.toUpperCase() == neopat);
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      backgroundColor: AppTheme.surface,
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CDC PORTAL',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Dashboard',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _isSyncing ? null : _handleSync,
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.accent,
                          ),
                        )
                      : const Icon(LucideIcons.rotateCw, size: 14),
                  label: Text(_isSyncing ? 'Syncing...' : 'Sync Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceLight.withValues(alpha: 0.5),
                    foregroundColor: AppTheme.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: AppTheme.border),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Student Profile Header Card
            if (widget.student != null) _buildStudentHeader(widget.student!),
            const SizedBox(height: 16),

            // Stat Cards Row
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    title: 'TOTAL DRIVES',
                    value: '${widget.companies.length}',
                    icon: LucideIcons.building2,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard(
                    title: 'MY SHORTLISTS',
                    value: '$shortlistedCount',
                    icon: LucideIcons.award,
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard(
                    title: 'NEOPAT MATCH',
                    value: '$neopatMatchedCount',
                    icon: LucideIcons.fingerprint,
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              onChanged: (val) => setState(() => searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Search companies or branches...',
                prefixIcon: Icon(LucideIcons.search, color: AppTheme.textSecondary),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('ALL', 'All Drives (${widget.companies.length})'),
                  const SizedBox(width: 8),
                  _filterChip('SHORTLISTED', 'My Shortlisted Companies ($shortlistedCount)'),
                  const SizedBox(width: 8),
                  _filterChip('NEOPAT', 'NeoPat Matched ($neopatMatchedCount)'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Placement Drives Title & Active Count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  activeFilter == 'SHORTLISTED'
                      ? 'My Shortlisted Companies'
                      : activeFilter == 'NEOPAT'
                          ? 'NeoPat Matched Companies'
                          : 'Campus Placement Drives',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${filteredCompanies.length} Found',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Companies List
            if (filteredCompanies.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    const Icon(LucideIcons.building, size: 36, color: AppTheme.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      activeFilter == 'SHORTLISTED'
                          ? 'You are not shortlisted in any company lists yet.'
                          : activeFilter == 'NEOPAT'
                              ? 'No company lists match your NeoPat ID (${widget.student?.neopatId ?? ""}).'
                              : 'No matching placement drives found.',
                      style: const TextStyle(color: AppTheme.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredCompanies.length,
                itemBuilder: (context, index) {
                  final company = filteredCompanies[index];
                  final isShortlisted = _isStudentShortlistedForCompany(company);
                  return CompanyCard(
                    company: company,
                    student: widget.student,
                    isShortlisted: isShortlisted,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => CompanyModal(
                          company: company,
                          student: widget.student,
                          isSelected: isShortlisted,
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentHeader(StudentModel student) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.surface,
            AppTheme.surfaceLight.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primary.withOpacity(0.2),
                child: const Icon(LucideIcons.user, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.email,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${student.degree} Student',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _infoTile('Reg No', student.regNo.isNotEmpty ? student.regNo : 'N/A'),
              const SizedBox(width: 40),
              _infoTile('NeoPat ID', student.neopatId.isNotEmpty ? student.neopatId : 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String filterKey, String label) {
    final isSelected = activeFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => activeFilter = filterKey),
      selectedColor: AppTheme.primary,
      backgroundColor: AppTheme.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.border),
      ),
    );
  }
}
