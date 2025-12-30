import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:five_six_seven_dance/l10n/app_localizations.dart';

// --- COMPONENTE: Tarjeta Superior de Tempo ---
class TempoControlCard extends StatelessWidget {
  final double bpm;
  final bool isPlaying;
  final String currentLanguage;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onBpmChanged;
  final ValueChanged<String> onLanguageChanged;

  const TempoControlCard({
    super.key,
    required this.bpm,
    required this.isPlaying,
    required this.currentLanguage,
    required this.onPlayPause,
    required this.onBpmChanged,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Map language codes to display names
    final languageDisplay = {
      'es': 'Español 🇲🇽',
      'en': 'Inglés 🇺🇸',
      'fr': 'Francés 🇫🇷',
      'ko': '한국어 🇰🇷',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Fila Superior: BPM Text, Idioma y Botón Play
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.tempoLabel.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        bpm.round().toString(),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'BPM',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  // Idioma Dropdown (Compacto)
                  PopupMenuButton<String>(
                    onSelected: onLanguageChanged,
                    offset: const Offset(0, 40),
                    color: AppColors.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    itemBuilder: (context) => languageDisplay.entries
                        .map(
                          (entry) => PopupMenuItem(
                            value: entry.key,
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inactiveButton,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.language_rounded,
                            color: AppColors.primaryOrange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            languageDisplay[currentLanguage] ?? 'Español 🇲🇽',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Botón Play
                  GestureDetector(
                    onTap: onPlayPause,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryOrange.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: AppColors.cardBackground,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Fila Media: Slider
          Row(
            children: [
              _CircleIconButton(
                icon: Icons.remove,
                onTap: () => onBpmChanged(bpm - 1),
              ),
              Expanded(
                child: Slider(
                  value: bpm,
                  min: 60,
                  max: 240,
                  onChanged: onBpmChanged,
                ),
              ),
              _CircleIconButton(
                icon: Icons.add,
                onTap: () => onBpmChanged(bpm + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Sub-componente auxiliar para los botones +/- del slider
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.inactiveButton,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
    );
  }
}
