import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static Future<void> checkForUpdates(BuildContext context, {bool showNoUpdate = false}) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('app_settings').select('latest_version, download_url').limit(1).maybeSingle();

      if (response == null) {
        if (showNoUpdate && context.mounted) _showUpToDateDialog(context);
        return;
      }

      final latestVersionStr = response['latest_version'] as String?;
      final downloadUrl = response['download_url'] as String?;

      if (latestVersionStr == null || downloadUrl == null) {
        if (showNoUpdate && context.mounted) _showUpToDateDialog(context);
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionStr = packageInfo.version;

      if (_isUpdateAvailable(currentVersionStr, latestVersionStr)) {
        if (!context.mounted) return;
        _showUpdateDialog(context, latestVersionStr, downloadUrl);
      } else {
        if (showNoUpdate && context.mounted) _showUpToDateDialog(context);
      }
    } catch (e) {
      debugPrint('Failed to check for updates: $e');
      if (showNoUpdate && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to check for updates.')),
        );
      }
    }
  }

  static bool _isUpdateAvailable(String currentVersion, String latestVersion) {
    final currentParts = currentVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final latestParts = latestVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      final curr = i < currentParts.length ? currentParts[i] : 0;
      final latest = i < latestParts.length ? latestParts[i] : 0;
      if (latest > curr) return true;
      if (latest < curr) return false;
    }
    return false;
  }

  static void _showUpdateDialog(BuildContext context, String latestVersion, String downloadUrl) {
    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissal
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Update Available'),
          content: Text('A new version of the app ($latestVersion) is available! Download the latest version to get the newest features and bug fixes.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                final uri = Uri.parse(downloadUrl);
                try {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (e) {
                  debugPrint('Failed to launch URL: $e');
                }
              },
              child: const Text('Download Update'),
            ),
          ],
        );
      },
    );
  }
  static void _showUpToDateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Up to Date'),
          content: const Text('You are already on the latest version of the app!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
