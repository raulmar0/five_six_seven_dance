import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'about_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
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
                'SUPPORT & INFO',
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
                      icon: Icons.help_outline,
                      title: 'Centro de Ayuda',
                      onTap: () {
                        _launchEmail(subject: 'bug - 567dance!');
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.info_outline,
                      title: 'Sobre la App',
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
                      icon: Icons.lightbulb,
                      title: 'Sugerencias',
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
                  '567 Dance! v1.0.4',
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

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(12))
            : const BorderRadius.vertical(
                top: Radius.circular(12),
              ), // Actually only one needs to be rounded if first/last
        // But for simplicity in a column, standard implementation:
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF4A3B30,
                  ), // Darker brownish bg for icon from screenshot
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
