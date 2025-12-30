import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import 'widgets/tempo_control_card.dart';
import 'widgets/instrument_section.dart';
import 'widgets/voice_count_section.dart';
import 'widgets/section_title.dart';
import 'audio/audio_engine.dart';
import 'audio/sequencer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Pre-load audio
  await AudioEngine().loadBaseAssets();
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
  String _currentLanguage = 'es';
  double _currentBPM = 180;
  bool _isPlaying = false;
  Map<String, int> _instrumentVolumes = {
    'Clave': 2,
    'Guiro': 2, // Also controls ShortGuiro
    'Bongo': 2, // Also controls ShortBongo
    'Cowbell': 2,
    'Bass': 2,
  };
  int _voiceVolume = 4; // 0-4
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

  late Sequencer _sequencer;

  @override
  void initState() {
    super.initState();
    _sequencer = Sequencer(
      onStep: () {
        // Could add visual feedback here
      },
    );
    // Sync initial state
    _sequencer.setBpm(_currentBPM);
    _sequencer.setLanguage(_currentLanguage);
    _sequencer.updateInstrumentVolumes(_instrumentVolumes);
    _sequencer.updateVoicePattern(_voiceStates);
    _sequencer.updateVoiceVolume(_voiceVolume);
  }

  @override
  void dispose() {
    _sequencer.stop();
    super.dispose();
  }

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
                currentLanguage: _currentLanguage,
                onPlayPause: () {
                  setState(() {
                    _isPlaying = !_isPlaying;
                    if (_isPlaying) {
                      _sequencer.play();
                    } else {
                      _sequencer.stop();
                    }
                  });
                },
                onBpmChanged: (val) {
                  // Clamp to prevent slider crash
                  final clampedBpm = val.clamp(60.0, 240.0);
                  setState(() => _currentBPM = clampedBpm);
                  _sequencer.setBpm(clampedBpm);
                },
                onLanguageChanged: (val) {
                  setState(() => _currentLanguage = val);
                  // Lazy load assets for new language
                  AudioEngine().loadLanguageAssets(val);
                  _sequencer.setLanguage(val);
                },
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
                      _sequencer.updateInstrumentVolumes(_instrumentVolumes);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- COMPONENTE 3: Sección de Conteo de Voz (FIJA) ---
              // La altura depende del contenido, no expandimos
              VoiceCountSection(
                voiceStates: _voiceStates,
                volume: _voiceVolume,
                onVolumeChanged: (vol) {
                  setState(() => _voiceVolume = vol);
                  _sequencer.updateVoiceVolume(vol);
                },
                onVoiceToggled: (index) {
                  setState(() {
                    _voiceStates[index] = !_voiceStates[index];
                  });
                  _sequencer.updateVoicePattern(_voiceStates);
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
