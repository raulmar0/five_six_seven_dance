import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import 'widgets/tempo_control_card.dart';
import 'widgets/instrument_section.dart';
import 'widgets/voice_count_section.dart';
import 'widgets/section_title.dart';

void main() {
  runApp(const SalsaMixerApp());
}

class SalsaMixerApp extends StatelessWidget {
  const SalsaMixerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '567 Dance!',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primaryOrange,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Configuración del tema del Slider para que sea naranja
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.primaryOrange,
          inactiveTrackColor: AppColors.inactiveButton,
          thumbColor: AppColors.textPrimary,
          overlayColor: AppColors.primaryOrange.withOpacity(0.2),
          trackHeight: 4.0,
        ),
      ),
      home: const SalsaMixerScreen(),
    );
  }
}

// ==========================================
// PANTALLA PRINCIPAL
// ==========================================
class SalsaMixerScreen extends StatefulWidget {
  const SalsaMixerScreen({super.key});

  @override
  State<SalsaMixerScreen> createState() => _SalsaMixerScreenState();
}

class _SalsaMixerScreenState extends State<SalsaMixerScreen> {
  // Estados de ejemplo para la UI
  String _currentRhythm = 'Salsa Dura';
  double _currentBPM = 180;
  bool _isPlaying = false;
  Map<String, int> _instrumentVolumes = {
    'Clave': 2,
    'Guiro': 1,
    'Guitar': 3,
    'Bongo': 0,
    'Cowbell': 4,
  };
  bool _isVoiceMuted = false;
  // Indices 0, 2, 4, 6 corresponden a los números 1, 3, 5, 7
  List<bool> _voiceStates = [
    true,
    false,
    true,
    false,
    true,
    false,
    true,
    false,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('567 Dance!'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      // Layout actualizado: Column con parte media expandida (instrumentos)
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- COMPONENTE 1: Tarjeta de Control de Tempo (FIJA) ---
              TempoControlCard(
                bpm: _currentBPM,
                isPlaying: _isPlaying,
                currentRhythm: _currentRhythm,
                onPlayPause: () => setState(() => _isPlaying = !_isPlaying),
                onBpmChanged: (val) => setState(() => _currentBPM = val),
                onRhythmChanged: (val) => setState(() => _currentRhythm = val),
              ),

              const SizedBox(height: 30),

              const SectionTitle(title: "INSTRUMENTOS"),

              const SizedBox(height: 16),

              // --- COMPONENTE 2: Sección de Instrumentos (SCROLLABLE) ---
              Expanded(
                child: SingleChildScrollView(
                  child: InstrumentSection(
                    instrumentVolumes: _instrumentVolumes,
                    onVolumeChanged: (name, volume) {
                      setState(() {
                        _instrumentVolumes[name] = volume;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- COMPONENTE 3: Sección de Conteo de Voz (FIJA) ---
              // La altura depende del contenido, no expandimos
              VoiceCountSection(
                voiceStates: _voiceStates,
                isMuted: _isVoiceMuted,
                onToggleMute: () =>
                    setState(() => _isVoiceMuted = !_isVoiceMuted),
                onVoiceToggled: (index) {
                  setState(() {
                    _voiceStates[index] = !_voiceStates[index];
                  });
                },
              ),
              // Espacio extra al final si se desea
              // const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
