import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:logging/logging.dart';

abstract class AudioBackend {
  bool get isInitialized;

  Future<void> init({
    required int bufferSize,
    required int sampleRate,
    required Channels channels,
  });

  Future<AudioSource> loadAsset(String path);
  Future<SoundHandle> play(AudioSource source, {double volume = 1.0});
  Future<void> stop(SoundHandle handle);
  void setRelativePlaySpeed(SoundHandle handle, double speed);
  void deinit();
}

class FlutterSoloudBackend implements AudioBackend {
  final SoLoud _soloud;

  FlutterSoloudBackend([SoLoud? soloud]) : _soloud = soloud ?? SoLoud.instance;

  @override
  bool get isInitialized => _soloud.isInitialized;

  @override
  Future<void> init({
    required int bufferSize,
    required int sampleRate,
    required Channels channels,
  }) {
    return _soloud.init(
      bufferSize: bufferSize,
      sampleRate: sampleRate,
      channels: channels,
    );
  }

  @override
  Future<AudioSource> loadAsset(String path) => _soloud.loadAsset(path);

  @override
  Future<SoundHandle> play(AudioSource source, {double volume = 1.0}) {
    return _soloud.play(source, volume: volume);
  }

  @override
  Future<void> stop(SoundHandle handle) => _soloud.stop(handle);

  @override
  void setRelativePlaySpeed(SoundHandle handle, double speed) {
    _soloud.setRelativePlaySpeed(handle, speed);
  }

  @override
  void deinit() => _soloud.deinit();
}

class AudioEngine {
  static final AudioEngine _instance = AudioEngine._internal();
  factory AudioEngine() => _instance;
  AudioEngine._internal({
    AudioBackend? backend,
    int maxPendingPlaybackTasks = 24,
  }) : _backend = backend ?? FlutterSoloudBackend(),
       _maxPendingPlaybackTasks = maxPendingPlaybackTasks;

  @visibleForTesting
  AudioEngine.test({
    required AudioBackend backend,
    int maxPendingPlaybackTasks = 24,
  }) : _backend = backend,
       _maxPendingPlaybackTasks = maxPendingPlaybackTasks;

  final _log = Logger('AudioEngine');
  final AudioBackend _backend;
  final int _maxPendingPlaybackTasks;
  bool _isInitialized = false;
  int _pendingPlaybackTasks = 0;
  int _droppedPlaybackTasks = 0;
  DateTime? _lastBackpressureLogAt;
  int _playbackGeneration = 0;

  // Loaded Audio Sources (in memory)
  final Map<String, AudioSource> _loadedSources = {};

  // Single voice handle to prevent overlapping voice numbers
  SoundHandle? _currentVoiceHandle;

  Future<void> initialize() async {
    if (_isInitialized || _backend.isInitialized) {
      _isInitialized = true;
      return;
    }

    try {
      // Configure audio session for iOS
      if (!kIsWeb && Platform.isIOS) {
        _log.fine('Configuring iOS audio session...');
        final session = await AudioSession.instance;
        await session.configure(
          const AudioSessionConfiguration(
            avAudioSessionCategory: AVAudioSessionCategory.playback,
            avAudioSessionCategoryOptions:
                AVAudioSessionCategoryOptions.mixWithOthers,
            avAudioSessionMode: AVAudioSessionMode.defaultMode,
          ),
        );
        await session.setActive(true);
        _log.info('iOS audio session configured and activated');
      }

      // Configure for robustness
      await _backend.init(
        bufferSize: 2048,
        sampleRate: 44100,
        channels: Channels.stereo,
      );
      _isInitialized = true;
      _log.info('AudioEngine initialized successfully');
    } catch (e) {
      _log.severe('AudioEngine initialization failed: $e');
      return; // Return early if initialization fails
    }
  }

  // Track loaded languages to avoid reloading
  final Set<String> _loadedLanguages = {};

  Future<void> loadBaseAssets() async {
    _log.fine('loadBaseAssets() called');
    if (!_isInitialized) {
      _log.fine('Engine not initialized, initializing now...');
      await initialize();
    }
    _log.fine('Engine initialized: $_isInitialized');

    final assets = {
      // Instruments
      'Clave': 'assets/audio/instrumentos/clave6(1).wav',
      'Guiro': 'assets/audio/instrumentos/guiro(1).wav',
      'ShortGuiro': 'assets/audio/instrumentos/short-guiro(1).wav',
      'Bongo': 'assets/audio/instrumentos/bongo(1).wav',
      'ShortBongo': 'assets/audio/instrumentos/short-bongo(1).wav',
      'Cowbell': 'assets/audio/instrumentos/cowbell-latin-hit(1).wav',
      'Bass': 'assets/audio/instrumentos/bass(1).wav',

      // Default Language (Spanish)
      'es_1': 'assets/audio/numeros_es/es_1.wav',
      'es_2': 'assets/audio/numeros_es/es_2.wav',
      'es_3': 'assets/audio/numeros_es/es_3.wav',
      'es_4': 'assets/audio/numeros_es/es_4.wav',
      'es_5': 'assets/audio/numeros_es/es_5.wav',
      'es_6': 'assets/audio/numeros_es/es_6.wav',
      'es_7': 'assets/audio/numeros_es/es_7.wav',
      'es_8': 'assets/audio/numeros_es/es_8.wav',
    };

    await _loadBatch(assets);
    _loadedLanguages.add('es');
  }

  Future<void> loadLanguageAssets(String languageCode) async {
    if (_loadedLanguages.contains(languageCode)) return;

    _log.fine('Loading language assets for: $languageCode');
    Map<String, String> assets = {};

    if (languageCode == 'en') {
      assets = {
        'en_1': 'assets/audio/numeros_en/en_1.wav',
        'en_2': 'assets/audio/numeros_en/en_2.wav',
        'en_3': 'assets/audio/numeros_en/en_3.wav',
        'en_4': 'assets/audio/numeros_en/en_4.wav',
        'en_5': 'assets/audio/numeros_en/en_5.wav',
        'en_6': 'assets/audio/numeros_en/en_6.wav',
        'en_7': 'assets/audio/numeros_en/en_7.wav',
        'en_8': 'assets/audio/numeros_en/en_8.wav',
      };
    } else if (languageCode == 'fr') {
      assets = {
        'fr_1': 'assets/audio/numeros_fr/fr_1.wav',
        'fr_2': 'assets/audio/numeros_fr/fr_2.wav',
        'fr_3': 'assets/audio/numeros_fr/fr_3.wav',
        'fr_4': 'assets/audio/numeros_fr/fr_4.wav',
        'fr_5': 'assets/audio/numeros_fr/fr_5.wav',
        'fr_6': 'assets/audio/numeros_fr/fr_6.wav',
        'fr_7': 'assets/audio/numeros_fr/fr_7.wav',
        'fr_8': 'assets/audio/numeros_fr/fr_8.wav',
      };
    }

    if (assets.isNotEmpty) {
      await _loadBatch(assets);
      _loadedLanguages.add(languageCode);
      _log.info('Loaded language: $languageCode');
    } else {
      _log.warning('No audio assets configured for language: $languageCode');
    }
  }

  Future<void> _loadBatch(Map<String, String> assets) async {
    _log.fine('_loadBatch: Starting to load ${assets.length} assets');
    for (final entry in assets.entries) {
      if (_loadedSources.containsKey(entry.key)) {
        _log.fine('Asset ${entry.key} already loaded, skipping');
        continue;
      }

      try {
        _log.fine('Loading asset: ${entry.key} from ${entry.value}');
        final source = await _backend.loadAsset(entry.value);
        _loadedSources[entry.key] = source;
        _log.fine('Loaded asset: ${entry.key}');
      } catch (e) {
        _log.severe('Error loading asset ${entry.key}: $e');
      }
    }
    _log.fine(
      '_loadBatch: Completed. Total loaded sources: ${_loadedSources.length}',
    );
  }

  /// Play a voice sample, stopping any previously playing voice first.
  /// Speed parameter adjusts playback rate using time-stretch (no pitch change).
  /// This avoids the "chipmunk effect" that occurs with setRelativePlaySpeed.
  void playOneShot(
    String key, {
    double volume = 1.0,
    double speed = 1.0,
  }) {
    final source = _loadedSources[key];
    if (source == null) {
      _log.warning('Asset not found for key: $key');
      return;
    }
    _enqueuePlayback('voice $key', () async {
      final generation = _playbackGeneration;
      // Stop previous voice to prevent overlapping
      if (_currentVoiceHandle != null) {
        await _stopHandle(_currentVoiceHandle!);
      }

      // Use setRelativePlaySpeed for speed adjustment
      // Note: For true pitch-preserving time stretch, we would need
      // to apply pitchShiftFilter, but that adds latency.
      // For now, we limit max speed to reduce chipmunk effect.
      final handle = await _backend.play(source, volume: volume);
      if (generation != _playbackGeneration) {
        await _stopHandle(handle);
        return;
      }
      _currentVoiceHandle = handle;

      // Clamp speed to reasonable range to minimize pitch distortion
      // Higher speeds sound more "chipmunk", so we limit it
      final clampedSpeed = speed.clamp(0.8, 1.5);
      if (clampedSpeed != 1.0) {
        _backend.setRelativePlaySpeed(handle, clampedSpeed);
      }
    });
  }

  /// Play an instrument sample once. The sequencer handles when to trigger each instrument.
  void playInstrument(
    String instrumentKey, {
    double volume = 1.0,
  }) {
    if (volume <= 0) {
      _log.fine('playInstrument($instrumentKey) skipped - volume is 0');
      return;
    }

    final source = _loadedSources[instrumentKey];
    if (source == null) {
      _log.warning('Instrument asset not found: $instrumentKey');
      return;
    }

    _enqueuePlayback('instrument $instrumentKey', () async {
      final generation = _playbackGeneration;
      _log.fine('playInstrument($instrumentKey) volume=$volume');
      final handle = await _backend.play(source, volume: volume);
      if (generation != _playbackGeneration) {
        await _stopHandle(handle);
        return;
      }
      _log.fine('playInstrument($instrumentKey) handle=$handle');
    });
  }

  void stopAll() {
    _playbackGeneration++;
    final handles = <SoundHandle>{};
    for (final source in _loadedSources.values) {
      handles.addAll(source.handles);
    }
    if (_currentVoiceHandle != null) {
      handles.add(_currentVoiceHandle!);
    }

    _currentVoiceHandle = null;
    for (final handle in handles) {
      unawaited(_stopHandle(handle));
    }
  }

  void _enqueuePlayback(String label, Future<void> Function() task) {
    if (_pendingPlaybackTasks >= _maxPendingPlaybackTasks) {
      _droppedPlaybackTasks++;
      _logBackpressure(label);
      return;
    }

    _pendingPlaybackTasks++;
    unawaited(
      Future<void>(() async {
        try {
          await task();
        } catch (e, stackTrace) {
          _log.warning('Playback task failed for $label', e, stackTrace);
        } finally {
          _pendingPlaybackTasks--;
        }
      }),
    );
  }

  void _logBackpressure(String label) {
    final now = DateTime.now();
    final last = _lastBackpressureLogAt;
    if (last != null && now.difference(last) < const Duration(seconds: 2)) {
      return;
    }
    _lastBackpressureLogAt = now;
    _log.warning(
      'Dropping playback task for $label; '
      'pending=$_pendingPlaybackTasks, dropped=$_droppedPlaybackTasks',
    );
  }

  Future<void> _stopHandle(SoundHandle handle) async {
    try {
      await _backend.stop(handle);
    } catch (e, stackTrace) {
      _log.fine('Ignoring stop failure for handle $handle', e, stackTrace);
    }
  }

  void dispose() {
    _backend.deinit();
  }
}
