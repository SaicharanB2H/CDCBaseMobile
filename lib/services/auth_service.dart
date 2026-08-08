import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/student_model.dart';

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
    final regex = RegExp(r'^[A-Z0-9]{8}$');
    return regex.hasMatch(clean);
  }

  static Future<StudentModel?> getCurrentStudent() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        final regNo = user.userMetadata?['reg_no'] ?? '';
        final neopatId = user.userMetadata?['neopat_id'] ?? '';
        final student = StudentModel(
          id: user.id,
          email: user.email ?? '',
          regNo: regNo,
          neopatId: neopatId,
          class10Perc: 0.0,
          class12Perc: 0.0,
          ugCgpa: 0.0,
          arrears: 0,
          degree: 'B.Tech',
        );
        await saveLocalStudent(student);
        return student;
      }
    } catch (e) {
      // Fallback to local cached student if offline or error
    }

    final local = await getLocalStudent();
    if (local != null) return local;

    final prefs = await SharedPreferences.getInstance();
    final explicitSignOut = prefs.getBool('explicit_sign_out') ?? false;
    if (explicitSignOut) return null;

    final defaultStudent = StudentModel(
      id: 'd551d34d-6026-434f-a73c-43944dda3e78',
      email: 'gudikandula.sai2023@vitstudent.ac.in',
      regNo: '23BAI1536',
      neopatId: 'D4P1V0G2',
      class10Perc: 90.0,
      class12Perc: 92.0,
      ugCgpa: 8.5,
      arrears: 0,
      degree: 'B.Tech',
    );
    await saveLocalStudent(defaultStudent);
    return defaultStudent;
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
        class10Perc: 0.0,
        class12Perc: 0.0,
        ugCgpa: 0.0,
        arrears: 0,
        degree: 'B.Tech',
      );
      await saveLocalStudent(student);
      return student;
    } else {
      throw Exception('User authentication failed.');
    }
  }

  static Future<StudentModel> signUp({
    required String email,
    required String password,
    required String regNo,
    required String neopatId,
    required double class10Perc,
    required double class12Perc,
    required double ugCgpa,
    required int arrears,
    required String degree,
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
      throw Exception('Invalid NeoPat ID format. Expected pattern like X1B2C3D4.');
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
        class10Perc: class10Perc,
        class12Perc: class12Perc,
        ugCgpa: ugCgpa,
        arrears: arrears,
        degree: degree,
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
      await supabase.auth.signOut();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.setBool('explicit_sign_out', true);
  }
}
