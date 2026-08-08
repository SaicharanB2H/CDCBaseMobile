import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'main_navigation.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isSignUp = false;
  bool loading = false;
  String errorMessage = '';

  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _regNoController = TextEditingController();
  final _neopatIdController = TextEditingController();
  final _class10Controller = TextEditingController();
  final _class12Controller = TextEditingController();
  final _cgpaController = TextEditingController();

  int arrears = 0;
  String degree = 'B.Tech';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _regNoController.dispose();
    _neopatIdController.dispose();
    _class10Controller.dispose();
    _class12Controller.dispose();
    _cgpaController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    setState(() {
      errorMessage = '';
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Please fill in both email and password.';
      });
      return;
    }

    if (!AuthService.validateVitEmail(email)) {
      setState(() {
        errorMessage = 'Access Restricted: You must use a valid @vitstudent.ac.in email address.';
      });
      return;
    }

    if (isSignUp) {
      if (!AuthService.validateRegNo(_regNoController.text)) {
        setState(() {
          errorMessage = 'Invalid Registration Number format. Expected pattern like 23BAI1506.';
        });
        return;
      }
      if (!AuthService.validateNeopatId(_neopatIdController.text)) {
        setState(() {
          errorMessage = 'Invalid NeoPat ID format. Expected pattern like X1B2C3D4.';
        });
        return;
      }
    }

    setState(() {
      loading = true;
    });

    try {
      if (isSignUp) {
        final student = await AuthService.signUp(
          email: email,
          password: password,
          regNo: _regNoController.text,
          neopatId: _neopatIdController.text,
          class10Perc: double.tryParse(_class10Controller.text) ?? 0.0,
          class12Perc: double.tryParse(_class12Controller.text) ?? 0.0,
          ugCgpa: double.tryParse(_cgpaController.text) ?? 0.0,
          arrears: arrears,
          degree: degree,
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MainNavigation(initialStudent: student)),
          );
        }
      } else {
        final student = await AuthService.signIn(
          email: email,
          password: password,
        );
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => MainNavigation(initialStudent: student)),
          );
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header Icon & Title
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryGradientStart, AppTheme.primaryGradientEnd],
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
                  child: const Icon(LucideIcons.graduationCap, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(
                  'MailBase CDC Portal',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  isSignUp ? 'Create your Student Placement Account' : 'Sign in to access your placement dashboard',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Error Message Box
                if (errorMessage.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
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

                // Form Fields
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'VIT Email (e.g. name.2023@vitstudent.ac.in)',
                          prefixIcon: Icon(LucideIcons.mail, color: AppTheme.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          hintText: 'Password',
                          prefixIcon: Icon(LucideIcons.lock, color: AppTheme.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Registration fields if Sign Up
                      if (isSignUp) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _regNoController,
                                decoration: const InputDecoration(
                                  hintText: 'Reg No (23BAI1506)',
                                  prefixIcon: Icon(LucideIcons.contact, color: AppTheme.textSecondary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _neopatIdController,
                                decoration: const InputDecoration(
                                  hintText: 'NeoPat ID (X1B2C3D4)',
                                  prefixIcon: Icon(LucideIcons.fingerprint, color: AppTheme.textSecondary),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _class10Controller,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: '10th %',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _class12Controller,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: '12th %',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _cgpaController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  hintText: 'CGPA',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: degree,
                                decoration: const InputDecoration(
                                  hintText: 'Degree',
                                ),
                                dropdownColor: AppTheme.surface,
                                items: ['B.Tech', 'M.Tech'].map((d) {
                                  return DropdownMenuItem(value: d, child: Text(d));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => degree = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: arrears,
                                decoration: const InputDecoration(
                                  hintText: 'Arrears',
                                ),
                                dropdownColor: AppTheme.surface,
                                items: [0, 1, 2, 3, 4, 5].map((a) {
                                  return DropdownMenuItem(
                                    value: a,
                                    child: Text(a == 0 ? '0 Arrears' : '$a Standing'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => arrears = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Auth Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: loading ? null : _handleAuth,
                          child: loading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(isSignUp ? 'Create Account' : 'Sign In'),
                                    const SizedBox(width: 8),
                                    const Icon(LucideIcons.arrowRight, size: 18),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Toggle Sign In / Sign Up
                      TextButton(
                        onPressed: () {
                          setState(() {
                            isSignUp = !isSignUp;
                            errorMessage = '';
                          });
                        },
                        child: Text(
                          isSignUp
                              ? 'Already have an account? Sign In'
                              : 'New student? Register your Profile',
                          style: const TextStyle(color: AppTheme.accent),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
