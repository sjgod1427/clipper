import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy for ClipVault',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Last updated: January 2026',
              style: TextStyle(fontSize: 13, color: subtitleColor),
            ),
            const SizedBox(height: 24),
            _buildSection(
              textColor: textColor,
              subtitleColor: subtitleColor!,
              title: '1. Information We Collect',
              content:
                  'ClipVault collects the following information to provide and improve our service:\n\n'
                  '• Account Information: When you register, we collect your email address, display name, and optional profile photo.\n\n'
                  '• Content Data: URLs, titles, descriptions, tags, and collection names you save within the app.\n\n'
                  '• Usage Data: We may collect information about how you interact with the app to improve user experience.\n\n'
                  '• Device Information: Basic device identifiers for authentication and app functionality.',
            ),
            _buildSection(
              textColor: textColor,
              subtitleColor: subtitleColor,
              title: '2. How We Use Your Information',
              content:
                  'We use the information we collect to:\n\n'
                  '• Provide, maintain, and improve the ClipVault service.\n\n'
                  '• Store and organize your saved content across collections.\n\n'
                  '• Auto-generate content details (titles, descriptions, tags) using AI when you use the Auto Generate feature.\n\n'
                  '• Authenticate your account and keep your data secure.\n\n'
                  '• Send important service-related notifications if you have opted in.',
            ),
            _buildSection(
              textColor: textColor,
              subtitleColor: subtitleColor,
              title: '3. Third-Party Services',
              content:
                  'ClipVault integrates with the following third-party services:\n\n'
                  '• Firebase (Google): For authentication, data storage (Firestore), and file storage. Data is processed according to Google\'s privacy policy.\n\n'
                  '• Google Gemini AI: When you use the Auto Generate feature, the URL you provide is sent to Google\'s Gemini API to generate content details. No personal data is sent.\n\n'
                  '• Instagram API (Optional): If you connect your Instagram account, we use Instagram\'s API to fetch content details for saved reels and posts. You can disconnect at any time from Settings.',
            ),
            _buildSection(
              textColor: textColor,
              subtitleColor: subtitleColor,
              title: '4. Data Storage & Security',
              content:
                  '• Your data is stored securely using Google Firebase infrastructure.\n\n'
                  '• All data transmission is encrypted using HTTPS/TLS.\n\n'
                  '• Your saved content is private and only accessible to your authenticated account.\n\n'
                  '• We do not sell, share, or rent your personal information to third parties.',
            ),
            _buildSection(
              textColor: textColor,
              subtitleColor: subtitleColor,
              title: '5. Your Rights & Controls',
              content:
                  'You have the following rights regarding your data:\n\n'
                  '• Access & Edit: You can view and edit your profile information at any time from the Settings screen.\n\n'
                  '• Delete Content: You can delete any saved content, collections, or tags at any time.\n\n'
                  '• Delete Account: You can permanently delete your account and all associated data from Settings > Privacy & Security.\n\n'
                  '• Notification Preferences: You can manage email and push notification settings from Privacy & Security.\n\n'
                  '• Disconnect Services: You can disconnect linked accounts (e.g., Instagram) at any time.',
            ),
            _buildSection(
              textColor: textColor,
              subtitleColor: subtitleColor,
              title: '6. Children\'s Privacy',
              content:
                  'ClipVault is not intended for use by children under the age of 13. We do not knowingly collect personal information from children under 13. If you believe we have collected information from a child under 13, please contact us so we can delete that information.',
            ),
            _buildSection(
              textColor: textColor,
              subtitleColor: subtitleColor,
              title: '7. Changes to This Policy',
              content:
                  'We may update this Privacy Policy from time to time. We will notify you of any changes by updating the "Last updated" date at the top of this policy. Continued use of the app after changes constitutes acceptance of the updated policy.',
            ),
            _buildSection(
              textColor: textColor,
              subtitleColor: subtitleColor,
              title: '8. Contact Us',
              content:
                  'If you have any questions or concerns about this Privacy Policy or our data practices, please contact us at:\n\n'
                  'Email: support@ClipVault.app',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required Color textColor,
    required Color subtitleColor,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 14, height: 1.5, color: subtitleColor),
          ),
        ],
      ),
    );
  }
}
