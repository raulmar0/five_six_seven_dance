import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_routes.dart';
import 'theme/app_colors.dart';
import 'widgets/tempo_control_card.dart';
import 'widgets/instrument_section.dart';
import 'widgets/voice_count_section.dart';
import 'widgets/section_title.dart';
import 'widgets/install_banner.dart';
import 'audio/audio_engine.dart';
import 'audio/sequencer.dart';
import 'screens/about_screen.dart';
import 'screens/settings_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:five_six_seven_dance/l10n/app_localizations.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    await AudioEngine().loadBaseAssets();
    FlutterNativeSplash.remove();
  }
  // On web, audio engine init is deferred to the first Play tap so the
  // underlying WebAudio AudioContext is created inside a user gesture
  // (required by iOS Safari).
  runApp(const SalsaMixerApp());
}

class SalsaMixerApp extends StatefulWidget {
  const SalsaMixerApp({super.key});

  @override
  State<SalsaMixerApp> createState() => _SalsaMixerAppState();
}

class _SalsaMixerAppState extends State<SalsaMixerApp> {
  Locale _locale = const Locale('es');

  void _changeLanguage(String languageCode) {
    setState(() {
      _locale = Locale(languageCode);
    });
    // On web, the engine isn't initialized until the first Play tap.
    // `_ensureAudioReady()` will load the current language when that happens.
    if (AudioEngine().isReady) {
      AudioEngine().loadLanguageAssets(languageCode);
    }
  }

  Route<void> _buildRoute(RouteSettings settings, Widget child) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => child,
    );
  }

  Route<void> _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
      case null:
        return _buildRoute(
          settings,
          SalsaMixerScreen(
            currentLanguage: _locale.languageCode,
            onLanguageChanged: _changeLanguage,
          ),
        );
      case AppRoutes.settings:
        return _buildRoute(
          settings,
          SettingsScreen(
            currentLanguage: _locale.languageCode,
            onLanguageChanged: _changeLanguage,
          ),
        );
      case AppRoutes.about:
        return _buildRoute(settings, const AboutScreen());
      default:
        return _buildRoute(
          const RouteSettings(name: AppRoutes.home),
          SalsaMixerScreen(
            currentLanguage: _locale.languageCode,
            onLanguageChanged: _changeLanguage,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '567 Dance!',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('es'), // Spanish
        Locale('fr'), // French
        Locale('ko'), // Korean
      ],
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
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.primaryOrange,
          inactiveTrackColor: AppColors.inactiveButton,
          thumbColor: AppColors.textPrimary,
          overlayColor: AppColors.primaryOrange.withValues(alpha: 0.2),
          trackHeight: 4.0,
        ),
      ),
      onGenerateRoute: _onGenerateRoute,
    );
  }
}

// ==========================================
// PANTALLA PRINCIPAL
// ==========================================
class SalsaMixerScreen extends StatefulWidget {
  final String currentLanguage;
  final Function(String) onLanguageChanged;

  const SalsaMixerScreen({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  State<SalsaMixerScreen> createState() => _SalsaMixerScreenState();
}

class _SalsaMixerScreenState extends State<SalsaMixerScreen>
    with WidgetsBindingObserver {
  // Estados de ejemplo para la UI
  // _currentLanguage is now passed from parent
  double _currentBPM = 130;
  bool _isPlaying = false;
  final Map<String, int> _instrumentVolumes = {
    'Clave': 2,
    'Guiro': 2, // Also controls ShortGuiro
    'Bongo': 2, // Also controls ShortBongo
    'Cowbell': 2,
    'Bass': 2,
  };
  int _voiceVolume = 4; // 0-4
  // Indices 0, 2, 4, 6 corresponden a los números 1, 3, 5, 7
  final List<bool> _voiceStates = [
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
  bool _isPreparingAudio = false;

  Future<void> _ensureAudioReady() async {
    if (AudioEngine().isReady) return;
    await AudioEngine().loadBaseAssets();
    if (widget.currentLanguage != 'es') {
      await AudioEngine().loadLanguageAssets(widget.currentLanguage);
    }
  }

  @override
  void initState() {
    super.initState();
    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    _sequencer = Sequencer(
      onStep: () {
        // Could add visual feedback here
      },
    );
    // Sync initial state
    _sequencer.setBpm(_currentBPM);
    _sequencer.setLanguage(widget.currentLanguage);
    _sequencer.updateInstrumentVolumes(_instrumentVolumes);
    _sequencer.updateVoicePattern(_voiceStates);
    _sequencer.updateVoiceVolume(_voiceVolume);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Stop playback when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (_isPlaying) {
        debugPrint('App went to background, stopping playback');
        _sequencer.stop();
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sequencer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
          ),
        ],
      ),
      // Layout: install banner on top, then existing content
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const InstallBanner(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TempoControlCard(
                      bpm: _currentBPM,
                      isPlaying: _isPlaying,
                      isPreparing: _isPreparingAudio,
                      currentLanguage: widget.currentLanguage,
                      onPlayPause: () async {
                        if (kIsWeb && !AudioEngine().isReady) {
                          setState(() => _isPreparingAudio = true);
                          await _ensureAudioReady();
                          if (!mounted) return;
                          setState(() => _isPreparingAudio = false);
                        }
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
                        final clampedBpm = val.clamp(60.0, 240.0);
                        setState(() => _currentBPM = clampedBpm);
                        _sequencer.setBpm(clampedBpm);
                      },
                      onLanguageChanged: (val) {
                        widget.onLanguageChanged(val);
                        _sequencer.setLanguage(val);
                      },
                    ),
                    const SizedBox(height: 30),
                    SectionTitle(
                      title: AppLocalizations.of(context)!.instrumentsLabel,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: InstrumentSection(
                          instrumentVolumes: _instrumentVolumes,
                          onVolumeChanged: (name, volume) {
                            setState(() {
                              _instrumentVolumes[name] = volume;
                            });
                            _sequencer.updateInstrumentVolumes(
                              _instrumentVolumes,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
