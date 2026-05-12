import 'package:flutter/material.dart';
import '../app_routes.dart';
import '../services/pwa_service.dart';
import '../theme/app_colors.dart';
import '../widgets/ios_install_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:five_six_seven_dance/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  final String currentLanguage;
  final ValueChanged<String> onLanguageChanged;

  const SettingsScreen({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PwaService _pwa = PwaService.instance;

  @override
  void initState() {
    super.initState();
    _pwa.addListener(_onPwaChange);
  }

  @override
  void dispose() {
    _pwa.removeListener(_onPwaChange);
    super.dispose();
  }

  void _onPwaChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final showInstall = _pwa.supportsInstall;
    final showUpdate = _pwa.isStandalone || _pwa.updateAvailable;
    final showAppSection = showInstall || showUpdate;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.settingsTitle),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              if (showAppSection) ...[
                _sectionHeader(t.appSection),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      if (showInstall)
                        _buildSettingsItem(
                          context,
                          icon: Icons.install_mobile,
                          title: t.installAppItem,
                          onTap: _handleInstall,
                          isLast: !showUpdate,
                        ),
                      if (showInstall && showUpdate) _buildDivider(),
                      if (showUpdate)
                        _buildSettingsItem(
                          context,
                          icon: _pwa.updateAvailable
                              ? Icons.system_update_alt
                              : Icons.refresh,
                          title: _pwa.updateAvailable
                              ? t.updateAvailableItem
                              : t.checkForUpdatesItem,
                          trailing: _pwa.updateAvailable
                              ? _updateBadge(context)
                              : null,
                          onTap: _handleUpdate,
                          isLast: true,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              _sectionHeader(t.supportInfoSection),
              const SizedBox(height: 12),
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
                      title: t.languageItem,
                      trailing: _buildLanguageBadge(widget.currentLanguage),
                      onTap: () => _showLanguageSelector(context),
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      context,
                      icon: Icons.help_outline,
                      title: t.helpCenterItem,
                      onTap: () {
                        _launchEmail(subject: 'bug - 567dance!');
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      context,
                      icon: Icons.info_outline,
                      title: t.aboutAppItem,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.about);
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      context,
                      icon: Icons.lightbulb,
                      title: t.suggestionsItem,
                      onTap: () {
                        _launchEmail(subject: 'suggestion - 567dance!');
                      },
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              Center(
                child: Text(
                  t.appVersion,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
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

  Widget _sectionHeader(String label) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.textSecondary.withValues(alpha: 0.7),
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _updateBadge(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: AppColors.primaryOrange,
        shape: BoxShape.circle,
      ),
    );
  }

  Future<void> _handleInstall() async {
    if (_pwa.isIOS) {
      await IosInstallSheet.show(context);
      return;
    }
    await _pwa.install();
  }

  Future<void> _handleUpdate() async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    if (_pwa.updateAvailable) {
      _pwa.applyUpdate();
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(t.checkingForUpdates),
        backgroundColor: AppColors.cardBackground,
        duration: const Duration(seconds: 2),
      ),
    );

    await _pwa.checkForUpdate();
    if (!mounted) return;

    if (_pwa.updateAvailable) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(t.updateReadyMessage),
          backgroundColor: AppColors.cardBackground,
          action: SnackBarAction(
            label: t.updateReadyAction,
            textColor: AppColors.primaryOrange,
            onPressed: _pwa.applyUpdate,
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    } else {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            t.upToDate,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.cardBackground,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
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
    final isSelected = widget.currentLanguage == code;
    return InkWell(
      onTap: () {
        widget.onLanguageChanged(code);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange.withValues(alpha: 0.1)
              : null,
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
      debugPrint('Could not launch email');
    }
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 56),
      height: 1,
      color: Colors.white.withValues(alpha: 0.05),
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
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
