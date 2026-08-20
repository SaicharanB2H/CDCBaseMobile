import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../data/models/student_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/network_util.dart';
import '../../services/auth_service.dart';
import '../../services/update_service.dart';
import '../theme/app_theme.dart';
import '../widgets/linkified_text.dart';

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
    String errorMessage = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isSaving = false;
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
                    const Text(
                      'Update Profile Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (errorMessage.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
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
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final hasInternet = await NetworkUtil.hasInternet();
                                if (!hasInternet && !widget.student!.isAnonymous) {
                                  if (context.mounted) NetworkUtil.showNoInternetDialog(context);
                                  return;
                                }

                                final newReg = regController.text.toUpperCase().trim();
                                final newNeopat = neopatController.text.toUpperCase().trim();

                                if (!AuthService.validateRegNo(newReg)) {
                                  setModalState(() {
                                    errorMessage = 'Invalid Registration Number format. Expected pattern like 23BAI1506.';
                                  });
                                  return;
                                }

                                if (!AuthService.validateNeopatId(newNeopat)) {
                                  setModalState(() {
                                    errorMessage = 'Invalid NeoPat ID format. Expected pattern like A1B2C3D4.';
                                  });
                                  return;
                                }

                                setModalState(() => isSaving = true);

                                final updated = widget.student!.copyWith(
                                  regNo: newReg,
                                  neopatId: newNeopat,
                                );

                                await AuthService.updateStudentProfile(updated);
                                
                                if (context.mounted) {
                                  Navigator.pop(context); // Pop the modal first
                                }
                                widget.onProfileUpdated(updated); // Update parent state after modal is gone
                              },
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save Profile Changes'),
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

  void _showChangePasswordSheet() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    String errorMessage = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isSaving = false;
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
                    const Text(
                      'Change Password',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (errorMessage.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.alertCircle, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextFormField(
                      controller: oldPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Old Password',
                        prefixIcon: Icon(LucideIcons.lock, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: Icon(LucideIcons.lock, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: Icon(LucideIcons.lock, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                final hasInternet = await NetworkUtil.hasInternet();
                                if (!hasInternet) {
                                  if (context.mounted) NetworkUtil.showNoInternetDialog(context);
                                  return;
                                }

                                final oldPass = oldPasswordController.text;
                                final newPass = newPasswordController.text;
                                final confirmPass = confirmPasswordController.text;

                                if (oldPass.isEmpty || newPass.isEmpty) {
                                  setModalState(() => errorMessage = 'All fields are required.');
                                  return;
                                }
                                if (newPass.length < 6) {
                                  setModalState(() => errorMessage = 'Password must be at least 6 characters.');
                                  return;
                                }
                                if (newPass != confirmPass) {
                                  setModalState(() => errorMessage = 'Passwords do not match.');
                                  return;
                                }

                                setModalState(() => isSaving = true);
                                
                                try {
                                  final supabase = Supabase.instance.client;
                                  
                                  // Verify old password
                                  await supabase.auth.signInWithPassword(
                                    email: widget.student!.email,
                                    password: oldPass,
                                  );

                                  // Update to new password
                                  await supabase.auth.updateUser(
                                    UserAttributes(password: newPass),
                                  );

                                  if (context.mounted) {
                                    Navigator.pop(context); // Close bottom sheet
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Password updated successfully!')),
                                    );
                                  }
                                } on AuthException catch (e) {
                                  setModalState(() {
                                    isSaving = false;
                                    if (e.message.contains('Invalid login credentials')) {
                                      errorMessage = 'Incorrect old password.';
                                    } else {
                                      errorMessage = e.message;
                                    }
                                  });
                                } catch (e) {
                                  setModalState(() {
                                    isSaving = false;
                                    errorMessage = 'An error occurred. Please try again.';
                                  });
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Change Password'),
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

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Account', style: TextStyle(color: AppTheme.error)),
        content: const Text(
          'Are you sure you want to delete your account? This will remove your local data and clear your profile details. This action cannot be undone.',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final hasInternet = await NetworkUtil.hasInternet();
    if (!hasInternet) {
      if (mounted) {
        NetworkUtil.showNoInternetDialog(context);
      }
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.error)),
    );

    await AuthService.deleteAccount();

    if (mounted) {
      Navigator.pop(context); // close loader
      widget.onSignOut();
    }
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
            onPressed: () async {
              final hasInternet = await NetworkUtil.hasInternet();
              if (!hasInternet) {
                if (context.mounted) {
                  NetworkUtil.showNoInternetDialog(context);
                }
                return;
              }
              _showEditSheet();
            },
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
                          color: AppTheme.primary.withValues(alpha: 0.3),
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
                          student.isAnonymous ? 'Anonymous User' : student.email,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reg No: ${student.regNo.isNotEmpty ? student.regNo : "Not Set"}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Profile Details List
                  if (!student.isAnonymous)
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
                  _profileItem(
                    icon: LucideIcons.globe,
                    title: 'Official Website',
                    value: 'https://cdcbasevit.duckdns.org',
                  ),
                  const SizedBox(height: 24),

                  if (!student.isAnonymous) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showChangePasswordSheet,
                        icon: const Icon(LucideIcons.lock, size: 18),
                        label: const Text('Change Password'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.surface,
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Check for Update Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => UpdateService.checkForUpdates(context, showNoUpdate: true),
                      icon: const Icon(LucideIcons.refreshCw, size: 18),
                      label: const Text('Check for Update'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surface,
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      label: const Text('Sign Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surface,
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Delete Account Button
                  if (!student.isAnonymous)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _deleteAccount,
                        icon: const Icon(LucideIcons.trash2, size: 18, color: AppTheme.error),
                        label: const Text('Delete Account', style: TextStyle(color: AppTheme.error)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                LinkifiedText(
                  text: value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  linkStyle: const TextStyle(
                    color: AppTheme.primary,
                    decoration: TextDecoration.underline,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  onLinkTap: (url) async {
                    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
                    try {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } catch (e) {
                      debugPrint('Could not launch $url: $e');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
