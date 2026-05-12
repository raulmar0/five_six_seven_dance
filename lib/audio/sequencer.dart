import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'audio_engine.dart';

/// Salsa rhythm pattern definition.
/// 16 steps per measure (8 beats × 2 sub-beats).
/// Each sub-step is identified as X.1 or X.2 (e.g., 1.1, 1.2, 2.1, 2.2...).
class SalsaRhythmPattern {
  /// Pattern: step index (0-15) -> list of instrument keys that play on that step
  static const Map<int, List<String>> pattern = {
    // 1.1 (step 0)
    0: ['Cowbell', 'Guiro'],
    // 1.2 (step 1)
    1: [],
    // 2.1 (step 2)
    2: ['Clave', 'ShortGuiro', 'ShortBongo'],
    // 2.2 (step 3)
    3: ['ShortGuiro'],
    // 3.1 (step 4)
    4: ['Clave', 'Guiro'],
    // 3.2 (step 5)
    5: [],
    // 4.1 (step 6)
    6: ['ShortGuiro', 'Bongo', 'Bass'],
    // 4.2 (step 7)
    7: ['ShortGuiro', 'Bongo'],
    // 5.1 (step 8)
    8: ['Cowbell', 'Clave', 'Guiro'],
    // 5.2 (step 9)
    9: [],
    // 6.1 (step 10)
    10: ['ShortGuiro', 'ShortBongo'],
    // 6.2 (step 11)
    11: ['Clave', 'ShortGuiro'],
    // 7.1 (step 12)
    12: ['Cowbell', 'Guiro'],
    // 7.2 (step 13)
    13: [],
    // 8.1 (step 14)
    14: ['Clave', 'ShortGuiro', 'Bongo', 'Bass'],
    // 8.2 (step 15)
    15: ['ShortGuiro', 'Bongo'],
  };

  /// Map instrument groups (for volume linking)
  /// When user adjusts Guiro volume, both Guiro and ShortGuiro use that volume.
  static String getVolumeKey(String instrument) {
    switch (instrument) {
      case 'ShortGuiro':
        return 'Guiro';
      case 'ShortBongo':
        return 'Bongo';
      default:
        return instrument;
    }
  }
}

abstract class SequencerClock {
  int get elapsedMilliseconds;
  void reset();
  void start();
  void stop();
}

class StopwatchSequencerClock implements SequencerClock {
  final Stopwatch _stopwatch = Stopwatch();

  @override
  int get elapsedMilliseconds => _stopwatch.elapsedMilliseconds;

  @override
  void reset() => _stopwatch.reset();

  @override
  void start() => _stopwatch.start();

  @override
  void stop() => _stopwatch.stop();
}

abstract class SequencerScheduler {
  void schedule(Duration delay, VoidCallback callback);
  void cancel();
}

class TimerSequencerScheduler implements SequencerScheduler {
  Timer? _timer;

  @override
  void schedule(Duration delay, VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  @override
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

abstract class SequencerPlayback {
  void playInstrument(String instrumentKey, {double volume = 1.0});
  void playOneShot(String key, {double volume = 1.0, double speed = 1.0});
  void stopAll();
}

class AudioEngineSequencerPlayback implements SequencerPlayback {
  final AudioEngine _audioEngine;

  AudioEngineSequencerPlayback([AudioEngine? audioEngine])
    : _audioEngine = audioEngine ?? AudioEngine();

  @override
  void playInstrument(String instrumentKey, {double volume = 1.0}) {
    _audioEngine.playInstrument(instrumentKey, volume: volume);
  }

  @override
  void playOneShot(String key, {double volume = 1.0, double speed = 1.0}) {
    _audioEngine.playOneShot(key, volume: volume, speed: speed);
  }

  @override
  void stopAll() {
    _audioEngine.stopAll();
  }
}

class Sequencer {
  final Logger _log = Logger('Sequencer');
  final SequencerPlayback _playback;
  final SequencerClock _clock;
  final SequencerScheduler _scheduler;

  // State
  bool isPlaying = false;
  double bpm = 180.0;
  String language = 'es'; // 'es', 'en', 'fr'

  // Timer vars
  int _startElapsedMs = 0;
  int _currentStepGlobal = 0; // Absolute step count since start

  // Callbacks
  final VoidCallback onStep; // To notify UI if needed (e.g. flashing lights)

  // Loop State passed from UI
  List<bool> voicePattern = List.filled(8, false);
  Map<String, int> instrumentVolumes = {};
  int voiceVolume = 4; // 0-4 range

  Sequencer({
    required this.onStep,
    SequencerPlayback? playback,
    SequencerClock? clock,
    SequencerScheduler? scheduler,
  }) : _playback = playback ?? AudioEngineSequencerPlayback(),
       _clock = clock ?? StopwatchSequencerClock(),
       _scheduler = scheduler ?? TimerSequencerScheduler();

  void setBpm(double newBpm) {
    if (isPlaying) {
      final now = _clock.elapsedMilliseconds;
      // Re-anchor start time to maintain position
      _startElapsedMs = now - (_currentStepGlobal * _msPerStep(newBpm)).round();
    }
    bpm = newBpm;
  }

  void setLanguage(String newLanguage) {
    language = newLanguage;
  }

  void updateVoicePattern(List<bool> newPattern) {
    voicePattern = newPattern;
  }

  void updateInstrumentVolumes(Map<String, int> newVolumes) {
    instrumentVolumes = newVolumes;
  }

  void updateVoiceVolume(int newVolume) {
    voiceVolume = newVolume;
  }

  void play() {
    _log.fine('Sequencer.play() called');
    if (isPlaying) return;
    isPlaying = true;
    _currentStepGlobal = 0;
    _clock.reset();
    _clock.start();
    _startElapsedMs = _clock.elapsedMilliseconds;
    _scheduleNextBeat();
  }

  void stop() {
    _log.fine('Sequencer.stop() called');
    isPlaying = false;
    _scheduler.cancel();
    _clock.stop();
    _playback.stopAll();
  }

  void _scheduleNextBeat() {
    if (!isPlaying) return;

    // 16 steps per measure (0-15)
    int stepIndex = _currentStepGlobal % 16;

    _playSoundsForStep(stepIndex);
    onStep(); // Notify UI

    _currentStepGlobal++;

    final nextExpectedElapsed =
        _startElapsedMs + (_currentStepGlobal * _msPerStep(bpm)).round();
    final now = _clock.elapsedMilliseconds;
    final waitTime = math.max(0, nextExpectedElapsed - now);

    // Drift correction: if lagging, execute immediately
    _scheduler.schedule(Duration(milliseconds: waitTime), _scheduleNextBeat);
  }

  void _playSoundsForStep(int stepIndex) {
    // A. Play instruments according to pattern
    final instruments = SalsaRhythmPattern.pattern[stepIndex] ?? [];
    for (final instrument in instruments) {
      // Get volume from the volume group (ShortGuiro uses Guiro volume, etc.)
      final volumeKey = SalsaRhythmPattern.getVolumeKey(instrument);
      final volumeLevel = instrumentVolumes[volumeKey] ?? 0;
      if (volumeLevel > 0) {
        // Map 0-4 to 0.0-1.0
        final normalizedVolume = volumeLevel / 4.0;
        _playback.playInstrument(instrument, volume: normalizedVolume);
      }
    }

    // B. Play voice on main beats only (x.1 steps = even indices: 0, 2, 4, 6, 8, 10, 12, 14)
    if (stepIndex % 2 == 0 && voiceVolume > 0) {
      // Convert step index to beat number (1-8)
      int beatNum = (stepIndex ~/ 2) + 1; // 0->1, 2->2, 4->3, etc.
      if (beatNum >= 1 && beatNum <= 8 && voicePattern[beatNum - 1]) {
        // Calculate voice speed based on BPM (similar to JS dynamicRate)
        final voiceSpeed = _calculateVoiceSpeed(bpm);

        // Calculate volume (0-4 -> 0.0-1.0)
        final normalizedVolume = voiceVolume / 4.0;

        _playback.playOneShot(
          '${language}_$beatNum',
          volume: normalizedVolume,
          speed: voiceSpeed,
        );
      }
    }
  }

  /// Calculate voice playback speed based on BPM.
  /// Uses linear interpolation to smoothly scale voice speed as BPM increases.
  ///
  /// The formula ensures:
  /// - Below 90 BPM: normal speed (1.0x)
  /// - 90-240 BPM: linear interpolation from 1.0x to maxSpeed
  /// - Above 240 BPM: capped at maxSpeed
  ///
  /// Max speed is limited to 1.5x as a balance between:
  /// - Ensuring voice samples complete before the next beat
  /// - Minimizing the "chipmunk effect" from pitch shifting
  ///
  /// Note: Speed is clamped again in AudioEngine.playOneShot() to 1.5 max.
  double _calculateVoiceSpeed(double bpm) {
    const double minBpm = 90.0; // Below this, use normal speed
    const double maxBpm = 240.0; // At/above this, use max speed
    const double minSpeed = 1.0; // Normal playback speed
    const double maxSpeed =
        1.6; // Max speed (balance between clarity and fitting in beat)

    if (bpm <= minBpm) {
      return minSpeed;
    }

    if (bpm >= maxBpm) {
      return maxSpeed;
    }

    // Linear interpolation between minBpm and maxBpm
    // Formula: speed = minSpeed + (bpm - minBpm) / (maxBpm - minBpm) * (maxSpeed - minSpeed)
    final double t = (bpm - minBpm) / (maxBpm - minBpm);
    return minSpeed + t * (maxSpeed - minSpeed);
  }

  double _msPerStep(double bpm) {
    // BPM is beats per minute. 1 Beat = one of the 8 counts.
    // We have 16 steps over 8 beats = 2 steps per beat.
    return (60.0 / bpm) * 500;
  }
}
