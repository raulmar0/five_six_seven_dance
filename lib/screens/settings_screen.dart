import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'about_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:five_six_seven_dance/l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  final String currentLanguage;
  final ValueChanged<String> onLanguageChanged;

  const SettingsScreen({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsTitle),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Section Header
              Text(
                AppLocalizations.of(context)!.supportInfoSection,
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              // Menu Options Card
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildSettingsItem(
                      context,
                      icon: Icons.language,
                      title: AppLocalizations.of(context)!.languageItem,
                      trailing: _buildLanguageBadge(currentLanguage),
                      onTap: () => _showLanguageSelector(context),
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      context,
                      icon: Icons.help_outline,
                      title: AppLocalizations.of(context)!.helpCenterItem,
                      onTap: () {
                        _launchEmail(subject: 'bug - 567dance!');
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      context,
                      icon: Icons.info_outline,
                      title: AppLocalizations.of(context)!.aboutAppItem,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      context,
                      icon: Icons.lightbulb,
                      title: AppLocalizations.of(context)!.suggestionsItem,
                      onTap: () {
                        _launchEmail(subject: 'suggestion - 567dance!');
                      },
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Version Footer
              Center(
                child: Text(
                  AppLocalizations.of(context)!.appVersion,
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageBadge(String code) {
    final languageFlags = {
      'es': '🇲🇽',
      'en': '🇺🇸',
      'fr': '🇫🇷',
      'ko': '🇰🇷',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inactiveButton,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        languageFlags[code] ?? code.toUpperCase(),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.languageItem,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildLanguageOption(context, 'es', 'Español', '🇲🇽'),
              _buildLanguageOption(context, 'en', 'English', '🇺🇸'),
              _buildLanguageOption(context, 'fr', 'Français', '🇫🇷'),
              _buildLanguageOption(context, 'ko', '한국어', '🇰🇷'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    String code,
    String name,
    String flag,
  ) {
    final isSelected = currentLanguage == code;
    return InkWell(
      onTap: () {
        onLanguageChanged(code);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryOrange.withOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primaryOrange
                      : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: AppColors.primaryOrange),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail({required String subject}) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'hello@raulmar.com',
      query: 'subject=$subject',
    );

    if (!await launchUrl(emailLaunchUri)) {
      print('Could not launch email');
    }
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 56), // Align with text
      height: 1,
      color: Colors.white.withOpacity(0.05),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(12))
            : const BorderRadius.vertical(top: Radius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A3B30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primaryOrange, size: 20),
              ),
              const SizedBox(width: 16),
              // Title
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null) ...[trailing, const SizedBox(width: 8)],
              // Chevron
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary.withOpacity(0.5),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
