import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/models/student_model.dart';
import '../../services/auth_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final StudentModel? student;
  final Function(StudentModel updated) onProfileUpdated;
  final VoidCallback onSignOut;

  const ProfileScreen({
    super.key,
    required this.student,
    required this.onProfileUpdated,
    required this.onSignOut,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showEditSheet() {
    if (widget.student == null) return;

    final regController = TextEditingController(text: widget.student!.regNo);
    final neopatController = TextEditingController(text: widget.student!.neopatId);
    final c10Controller = TextEditingController(text: widget.student!.class10Perc.toString());
    final c12Controller = TextEditingController(text: widget.student!.class12Perc.toString());
    final cgpaController = TextEditingController(text: widget.student!.ugCgpa.toString());

    int arrears = widget.student!.arrears;
    String degree = widget.student!.degree;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
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
                    const SizedBox(height: 16),
                    Text(
                      'Edit Academic Profile',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: regController,
                      decoration: const InputDecoration(
                        labelText: 'Registration Number',
                        prefixIcon: Icon(LucideIcons.contact, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: neopatController,
                      decoration: const InputDecoration(
                        labelText: 'NeoPat ID',
                        prefixIcon: Icon(LucideIcons.fingerprint, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: c10Controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: '10th %'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: c12Controller,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: '12th %'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: cgpaController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'UG CGPA'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: degree,
                            decoration: const InputDecoration(labelText: 'Degree'),
                            dropdownColor: AppTheme.surface,
                            items: ['B.Tech', 'M.Tech'].map((d) {
                              return DropdownMenuItem(value: d, child: Text(d));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => degree = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: arrears,
                            decoration: const InputDecoration(labelText: 'Arrears'),
                            dropdownColor: AppTheme.surface,
                            items: [0, 1, 2, 3, 4, 5].map((a) {
                              return DropdownMenuItem(
                                value: a,
                                child: Text(a == 0 ? '0 Arrears' : '$a Standing'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => arrears = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final updated = widget.student!.copyWith(
                            regNo: regController.text.toUpperCase().trim(),
                            neopatId: neopatController.text.toUpperCase().trim(),
                            class10Perc: double.tryParse(c10Controller.text) ?? widget.student!.class10Perc,
                            class12Perc: double.tryParse(c12Controller.text) ?? widget.student!.class12Perc,
                            ugCgpa: double.tryParse(cgpaController.text) ?? widget.student!.ugCgpa,
                            arrears: arrears,
                            degree: degree,
                          );

                          await AuthService.updateStudentProfile(updated);
                          widget.onProfileUpdated(updated);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('Save Profile Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.student;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text('Student Profile', style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit, color: AppTheme.primary),
            onPressed: _showEditSheet,
          ),
        ],
      ),
      body: student == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryGradientStart, AppTheme.primaryGradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white24,
                          child: Icon(LucideIcons.userCheck, size: 40, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          student.email,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${student.degree} Candidate • Reg No: ${student.regNo.isNotEmpty ? student.regNo : "Not Set"}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Profile Details List
                  _profileItem(
                    icon: LucideIcons.mail,
                    title: 'VIT Email Address',
                    value: student.email,
                  ),
                  _profileItem(
                    icon: LucideIcons.contact,
                    title: 'Registration Number',
                    value: student.regNo.isNotEmpty ? student.regNo : 'Not Onboarded',
                  ),
                  _profileItem(
                    icon: LucideIcons.fingerprint,
                    title: 'NeoPat ID',
                    value: student.neopatId.isNotEmpty ? student.neopatId : 'Not Onboarded',
                  ),
                  const SizedBox(height: 14),
                  const SizedBox(height: 24),

                  // Edit Profile Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showEditSheet,
                      icon: const Icon(LucideIcons.edit3, size: 18),
                      label: const Text('Update Academic Information'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.primary),
                        foregroundColor: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onSignOut,
                      icon: const Icon(LucideIcons.logOut, size: 18),
                      label: const Text('Sign Out of Portal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.2),
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _profileItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
