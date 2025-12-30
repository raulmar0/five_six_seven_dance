import 'dart:async';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:logging/logging.dart';

class AudioEngine {
  static final AudioEngine _instance = AudioEngine._internal();
  factory AudioEngine() => _instance;
  AudioEngine._internal();

  final _log = Logger('AudioEngine');
  bool _isInitialized = false;

  // SoLoud instance
  late final SoLoud _soloud;

  // Loaded Audio Sources (in memory)
  final Map<String, AudioSource> _loadedSources = {};

  // Single voice handle to prevent overlapping voice numbers
  SoundHandle? _currentVoiceHandle;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _soloud = SoLoud.instance;
      // Configure for robustness on Android Emulator
      await _soloud.init(
        bufferSize: 2048,
        sampleRate: 44100,
        channels: Channels.stereo,
      );
      _isInitialized = true;
      print('✅ AudioEngine initialized successfully');
      _log.info('AudioEngine initialized successfully');
    } catch (e) {
      print('❌ AudioEngine initialization failed: $e');
      _log.severe('AudioEngine initialization failed: $e');
      return; // Return early if initialization fails
    }
  }

  Future<void> loadAssets() async {
    if (!_isInitialized) await initialize();

    final assets = {
      // Instruments
      'Clave': 'assets/audio/instrumentos/clave6(1).wav',
      'Guiro': 'assets/audio/instrumentos/guiro(1).wav',
      'ShortGuiro': 'assets/audio/instrumentos/short-guiro(1).wav',
      'Bongo': 'assets/audio/instrumentos/bongo(1).wav',
      'ShortBongo': 'assets/audio/instrumentos/short-bongo(1).wav',
      'Cowbell': 'assets/audio/instrumentos/cowbell-latin-hit(1).wav',
      'Bass': 'assets/audio/instrumentos/bass(1).wav',

      // Voice (1-8)
      '1': 'assets/audio/numeros_es/es_1.wav',
      '2': 'assets/audio/numeros_es/es_2.wav',
      '3': 'assets/audio/numeros_es/es_3.wav',
      '4': 'assets/audio/numeros_es/es_4.wav',
      '5': 'assets/audio/numeros_es/es_5.wav',
      '6': 'assets/audio/numeros_es/es_6.wav',
      '7': 'assets/audio/numeros_es/es_7.wav',
      '8': 'assets/audio/numeros_es/es_8.wav',
    };

    for (final entry in assets.entries) {
      try {
        final source = await _soloud.loadAsset(entry.value);
        _loadedSources[entry.key] = source;
        print('✅ Loaded asset: ${entry.key} -> ${entry.value}');
      } catch (e) {
        print('❌ Error loading asset ${entry.key}: $e');
        _log.severe('Error loading asset ${entry.key}: $e');
      }
    }
    print('🎵 AudioEngine: Loaded ${_loadedSources.length} assets');
  }

  /// Play a voice sample, stopping any previously playing voice first.
  /// Speed parameter adjusts playback rate (1.0 = normal, 2.0 = double speed).
  Future<void> playOneShot(
    String key, {
    double volume = 1.0,
    double speed = 1.0,
  }) async {
    final source = _loadedSources[key];
    if (source == null) {
      print('⚠️ Asset not found for key: $key');
      _log.warning('Asset not found for key: $key');
      return;
    }
    try {
      // Stop previous voice to prevent overlapping
      if (_currentVoiceHandle != null) {
        try {
          _soloud.stop(_currentVoiceHandle!);
        } catch (_) {
          // Handle might already be invalid, ignore
        }
      }
      _currentVoiceHandle = await _soloud.play(source, volume: volume);

      // Adjust playback speed if needed
      if (speed != 1.0) {
        _soloud.setRelativePlaySpeed(_currentVoiceHandle!, speed);
      }
    } catch (e) {
      print('❌ Error playing OneShot $key: $e');
    }
  }

  /// Play an instrument sample once. The sequencer handles when to trigger each instrument.
  Future<void> playInstrument(
    String instrumentKey, {
    double volume = 1.0,
  }) async {
    if (volume <= 0) return; // Don't play if muted

    final source = _loadedSources[instrumentKey];
    if (source == null) {
      _log.warning('Instrument asset not found: $instrumentKey');
      return;
    }

    try {
      await _soloud.play(source, volume: volume);
    } catch (e) {
      _log.severe('Error playing instrument $instrumentKey: $e');
    }
  }

  void stopAll() {
    // Stop any playing voice
    if (_currentVoiceHandle != null) {
      try {
        _soloud.stop(_currentVoiceHandle!);
      } catch (_) {}
      _currentVoiceHandle = null;
    }
  }

  void dispose() {
    _soloud.deinit();
  }
}
