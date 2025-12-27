import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';

// --- COMPONENTE: Sección de Instrumentos (Lista) ---
class InstrumentSection extends StatelessWidget {
  final Map<String, int> instrumentVolumes;
  final Function(String, int) onVolumeChanged;

  const InstrumentSection({
    super.key,
    required this.instrumentVolumes,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mapeamos los datos a widgets InstrumentTile
        ...instrumentVolumes.entries.map((entry) {
          return InstrumentTile(
            name: entry.key,
            volume: entry.value,
            onVolumeChanged: (newVol) => onVolumeChanged(entry.key, newVol),
          );
        }).toList(),
      ],
    );
  }
}

// --- COMPONENTE: Fila Individual de Instrumento (Tile) ---
class InstrumentTile extends StatelessWidget {
  final String name;
  final int volume;
  final ValueChanged<int> onVolumeChanged;

  const InstrumentTile({
    super.key,
    required this.name,
    required this.volume,
    required this.onVolumeChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Increment volume logic: 0 -> 1 -> 2 -> 3 -> 4 -> 0
    void handleTap() {
      int nextVolume = (volume + 1) > 4 ? 0 : (volume + 1);
      onVolumeChanged(nextVolume);
    }

    // Determinamos icono basado en el nombre
    IconData iconData = Icons.graphic_eq;
    if (name.toLowerCase().contains('clave')) iconData = Icons.straighten;
    if (name.toLowerCase().contains('guiro')) iconData = Icons.reorder;
    if (name.toLowerCase().contains('guitar')) iconData = Icons.music_note;
    if (name.toLowerCase().contains('bongo')) iconData = Icons.lens_blur;
    if (name.toLowerCase().contains('cowbell') ||
        name.toLowerCase().contains('campana')) {
      iconData = Icons.notifications_active;
    }

    final bool isActive = volume > 0;
    final Color itemsColor = isActive
        ? AppColors.textPrimary
        : AppColors.textSecondary;
    final Color iconBgColor = isActive
        ? AppColors.instrumentIconBg
        : AppColors.inactiveButton.withOpacity(0.5);

    return GestureDetector(
      onTap: handleTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Icono Cuadrado
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconData,
                color: isActive
                    ? AppColors.primaryOrange
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            // Nombre y Barras de Volumen
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: itemsColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Indicador de volumen visual (ahora real basado en volumen)
                  Row(
                    children: List.generate(4, (index) {
                      // Se prenden tantas barras como nivel de volumen
                      Color barColor = (index < volume)
                          ? AppColors.indicatorBlue
                          : AppColors.inactiveButton;

                      return Container(
                        margin: const EdgeInsets.only(right: 4),
                        width: 16,
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
            // Switch estilo iOS que responde al volumen > 0
            CupertinoSwitch(
              value: isActive,
              onChanged: (val) => onVolumeChanged(val ? 1 : 0),
              activeColor: AppColors.primaryOrange,
              trackColor: AppColors.inactiveButton,
            ),
          ],
        ),
      ),
    );
  }
}
