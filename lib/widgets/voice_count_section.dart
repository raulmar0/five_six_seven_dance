import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'section_title.dart';
import 'package:five_six_seven_dance/l10n/app_localizations.dart';

// --- COMPONENTE: Sección de Conteo de Voz y Grid ---
class VoiceCountSection extends StatelessWidget {
  final List<bool> voiceStates;
  final Function(int) onVoiceToggled;
  final int volume; // 0-4
  final ValueChanged<int> onVolumeChanged;

  const VoiceCountSection({
    super.key,
    required this.voiceStates,
    required this.onVoiceToggled,
    required this.volume,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Volume cycle logic: 0 -> 1 -> 2 -> 3 -> 4 -> 0
    void handleVolumeTap() {
      int nextVolume = (volume + 1) > 4 ? 0 : (volume + 1);
      onVolumeChanged(nextVolume);
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SectionTitle(
                title: AppLocalizations.of(context)!.voiceLabel.toUpperCase(),
              ),
              // Volume Control
              GestureDetector(
                onTap: handleVolumeTap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.inactiveButton.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        volume == 0
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        color: volume > 0
                            ? AppColors.primaryOrange
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      // Volume Bars
                      Row(
                        children: List.generate(4, (index) {
                          Color barColor = (index < volume)
                              ? AppColors.indicatorBlue
                              : AppColors.inactiveButton;
                          return Container(
                            margin: const EdgeInsets.only(right: 4),
                            width: 12,
                            height: 6,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Primera fila (1-4)
          Row(
            children: List.generate(4, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 3 ? 0 : 8),
                  child: VoiceGridButton(
                    number: index + 1,
                    isActive: voiceStates[index],
                    onTap: () => onVoiceToggled(index),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // Segunda fila (5-8)
          Row(
            // ... rest keeps same logic ...
            children: List.generate(4, (index) {
              final buttonIndex = index + 4;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 3 ? 0 : 8),
                  child: VoiceGridButton(
                    number: buttonIndex + 1,
                    isActive: voiceStates[buttonIndex],
                    onTap: () => onVoiceToggled(buttonIndex),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// --- COMPONENTE: Botón Individual del Grid (1-8) ---
class VoiceGridButton extends StatelessWidget {
  final int number;
  final bool isActive;
  final VoidCallback onTap;

  const VoiceGridButton({
    super.key,
    required this.number,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        height: 44, // Altura táctil recomendada
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryOrange : AppColors.inactiveButton,
          borderRadius: BorderRadius.circular(12),
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryOrange,
                    AppColors.primaryOrange.withOpacity(0.8),
                  ],
                )
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primaryOrange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            number.toString(),
            style: TextStyle(
              fontSize: 18, // Texto más legible
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
