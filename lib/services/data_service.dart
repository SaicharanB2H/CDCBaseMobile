import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/company_model.dart';
import '../data/models/event_model.dart';

class DataService {
  static const String _companiesKey = 'cached_companies';
  static const String _eventsKey = 'cached_events';

  static Future<List<CompanyModel>> fetchCompanies({bool forceSync = false}) async {
    if (forceSync) {
      return fetchCompaniesFromRemote();
    } else {
      return loadCompaniesLocally();
    }
  }

  static Future<List<EventModel>> fetchEvents({bool forceSync = false}) async {
    if (forceSync) {
      return fetchEventsFromRemote();
    } else {
      return loadEventsLocally();
    }
  }

  // Fetch companies from Supabase and save locally
  static Future<List<CompanyModel>> fetchCompaniesFromRemote() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('companies')
        .select('company_name, ctc, stipend, visit_date, branches, eligibility, deadline, links, location, event_timeline, selected, selected_reg, received_at');

    if (response.isEmpty) {
      await saveCompaniesLocally([]);
      return [];
    }

    final list = (response as List)
        .map((json) => CompanyModel.fromJson(json))
        .toList();

    await saveCompaniesLocally(list);
    return list;
  }

  // Load companies from SharedPreferences
  static Future<List<CompanyModel>> loadCompaniesLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_companiesKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => CompanyModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Failed to parse local companies: $e');
      return [];
    }
  }

  // Save companies to SharedPreferences
  static Future<void> saveCompaniesLocally(List<CompanyModel> companies) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = companies.map((c) => c.toJson()).toList();
    await prefs.setString(_companiesKey, jsonEncode(jsonList));
  }

  // Fetch events from Supabase and save locally
  static Future<List<EventModel>> fetchEventsFromRemote() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('events')
        .select('id, company_name, subject, body, links, shortlisted_regs, created_at, scheduled_date_time, received_at');

    if (response.isEmpty) {
      await saveEventsLocally([]);
      return [];
    }

    final list = (response as List)
        .map((json) => EventModel.fromJson(json))
        .toList();

    await saveEventsLocally(list);
    return list;
  }

  // Load events from SharedPreferences
  static Future<List<EventModel>> loadEventsLocally() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_eventsKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => EventModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Failed to parse local events: $e');
      return [];
    }
  }

  // Save events to SharedPreferences
  static Future<void> saveEventsLocally(List<EventModel> events) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = events.map((e) => e.toJson()).toList();
    await prefs.setString(_eventsKey, jsonEncode(jsonList));
  }
}
