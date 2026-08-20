import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/student_model.dart';
import '../utils/network_util.dart';

class AuthService {
  static const String _sessionKey = 'cdc_student_session';

  static bool validateVitEmail(String email) {
    return email.trim().toLowerCase().endsWith('@vitstudent.ac.in');
  }

  static bool validateRegNo(String regNo) {
    final clean = regNo.trim().toUpperCase();
    final regex = RegExp(r'^[0-9]{2}[A-Z]{3}[0-9]{4}$');
    return regex.hasMatch(clean);
  }

  static bool validateNeopatId(String neopatId) {
    final clean = neopatId.trim().toUpperCase();
    final regex = RegExp(r'^([A-Z][0-9]){4}$');
    return regex.hasMatch(clean);
  }

  static Future<StudentModel?> getCurrentStudent() async {
    try {

      final supabase = Supabase.instance.client;
      
      // Check network first so we don't delay startup if offline
      final hasInternet = await NetworkUtil.hasInternet();
      if (hasInternet) {
        try {
          // This verifies the session with the server. If the user was deleted
          // from the backend, this will throw an AuthException.
          await supabase.auth.getUser();
        } on AuthException catch (e) {
          // Only force sign out if we get a definitive "User not found" error.
          // Other AuthExceptions (like temporary token expiration delays) shouldn't log the user out.
          if (e.message.toLowerCase().contains('user not found')) {
            await signOut();
            return null;
          }
        } catch (_) {}
      }

      final user = supabase.auth.currentUser;

      if (user != null) {
        final regNo = user.userMetadata?['reg_no'] ?? '';
        final neopatId = user.userMetadata?['neopat_id'] ?? '';
        final isAnonymousUser = user.isAnonymous;
        final student = StudentModel(
          id: user.id,
          email: user.email ?? '',
          regNo: regNo,
          neopatId: neopatId,
          isAnonymous: isAnonymousUser,
        );
        await saveLocalStudent(student);
        return student;
      }
    } catch (e) {
      // Fallback to local cached student if offline or error
    }

    final local = await getLocalStudent();
    return local;
  }

  static Future<void> saveLocalStudent(StudentModel student) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(student.toJson()));
    await prefs.remove('explicit_sign_out');
  }

  static Future<StudentModel?> getLocalStudent() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_sessionKey);
    if (jsonStr != null) {
      try {
        final map = jsonDecode(jsonStr);
        return StudentModel.fromJson(map);
      } catch (_) {}
    }
    return null;
  }

  static Future<StudentModel> signIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    if (!validateVitEmail(cleanEmail)) {
      throw Exception('Access Restricted: You must use a valid @vitstudent.ac.in email address.');
    }

    final supabase = Supabase.instance.client;
    final authResponse = await supabase.auth.signInWithPassword(
      email: cleanEmail,
      password: password,
    );

    final user = authResponse.user;
    if (user != null) {
      final regNo = user.userMetadata?['reg_no'] ?? '';
      final neopatId = user.userMetadata?['neopat_id'] ?? '';
      final student = StudentModel(
        id: user.id,
        email: user.email ?? '',
        regNo: regNo,
        neopatId: neopatId,

      );
      await saveLocalStudent(student);
      return student;
    } else {
      throw Exception('User authentication failed.');
    }
  }

  static Future<StudentModel> signInAnonymously({
    required String regNo,
    required String neopatId,
  }) async {
    final cleanRegNo = regNo.trim().toUpperCase();
    final cleanNeopatId = neopatId.trim().toUpperCase();

    if (!validateRegNo(cleanRegNo)) {
      throw Exception('Invalid Registration Number format. Expected pattern like 23BAI1506.');
    }

    if (!validateNeopatId(cleanNeopatId)) {
      throw Exception('Invalid NeoPat ID format. Expected pattern like A1B2C3D4.');
    }

    final supabase = Supabase.instance.client;
    final authResponse = await supabase.auth.signInAnonymously();
    final user = authResponse.user;

    if (user != null) {
      // Store their reg no and neopat id in their Supabase anonymous profile metadata
      try {
        await supabase.auth.updateUser(
          UserAttributes(
            data: {
              'reg_no': cleanRegNo,
              'neopat_id': cleanNeopatId,
            },
          ),
        );
      } catch (e) {
        debugPrint('Failed to update anonymous user metadata: $e');
      }
    }

    final student = StudentModel(
      id: user?.id ?? 'anonymous',
      email: '',
      regNo: cleanRegNo,
      neopatId: cleanNeopatId,
      isAnonymous: true,
    );

    await saveLocalStudent(student);
    return student;
  }

  static Future<StudentModel> signUp({
    required String email,
    required String password,
    required String regNo,
    required String neopatId,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanRegNo = regNo.trim().toUpperCase();
    final cleanNeopatId = neopatId.trim().toUpperCase();

    if (!validateVitEmail(cleanEmail)) {
      throw Exception('Access Restricted: You must use a valid @vitstudent.ac.in email address.');
    }

    if (!validateRegNo(cleanRegNo)) {
      throw Exception('Invalid Registration Number format. Expected pattern like 23BAI1506.');
    }

    if (!validateNeopatId(cleanNeopatId)) {
      throw Exception('Invalid NeoPat ID format. Expected pattern like A1B2C3.');
    }

    final supabase = Supabase.instance.client;
    final authData = await supabase.auth.signUp(
      email: cleanEmail,
      password: password,
      data: {
        'reg_no': cleanRegNo,
        'neopat_id': cleanNeopatId,
      },
    );

    final user = authData.user;
    if (user != null) {
      final student = StudentModel(
        id: user.id,
        email: cleanEmail,
        regNo: cleanRegNo,
        neopatId: cleanNeopatId,
      );

      await saveLocalStudent(student);
      return student;
    } else {
      throw Exception('User registration failed.');
    }
  }

  static Future<StudentModel> updateStudentProfile(StudentModel updatedStudent) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'reg_no': updatedStudent.regNo,
            'neopat_id': updatedStudent.neopatId,
          },
        ),
      );
    } catch (_) {}

    await saveLocalStudent(updatedStudent);
    return updatedStudent;
  }

  static Future<void> signOut() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user != null && user.isAnonymous) {
        try {
          await supabase.rpc('delete_user');
        } catch (_) {}
      }
      
      await supabase.auth.signOut();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.setBool('explicit_sign_out', true);
  }

  static Future<void> deleteAccount() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user != null) {
        // Clear user metadata to remove personal details
        try {
          await supabase.auth.updateUser(
            UserAttributes(
              data: {
                'reg_no': '',
                'neopat_id': '',
              },
            ),
          );
        } catch (_) {}
        
        // Call the backend RPC to securely delete the auth user
        try {
          await supabase.rpc('delete_user');
        } catch (e) {
          throw Exception('Failed to delete user via RPC: $e');
        }
      }
      
      await supabase.auth.signOut();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.setBool('explicit_sign_out', true);
  }
}
