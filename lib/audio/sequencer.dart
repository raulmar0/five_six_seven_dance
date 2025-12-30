import 'dart:async';
import 'package:flutter/foundation.dart';
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

class Sequencer {
  final AudioEngine _audioEngine = AudioEngine();

  // State
  bool isPlaying = false;
  double bpm = 180.0;
  String language = 'es'; // 'es', 'en', 'fr'

  // Timer vars
  int _startTime = 0;
  int _currentStepGlobal = 0; // Absolute step count since start
  Timer? _timer;

  // Callbacks
  final VoidCallback onStep; // To notify UI if needed (e.g. flashing lights)

  // Loop State passed from UI
  List<bool> voicePattern = List.filled(8, false);
  Map<String, int> instrumentVolumes = {};
  int voiceVolume = 4; // 0-4 range

  Sequencer({required this.onStep});

  void setBpm(double newBpm) {
    if (isPlaying) {
      final now = DateTime.now().millisecondsSinceEpoch;
      // 16 steps over 8 beats = 2 steps per beat
      double newSecPerStep = (60.0 / newBpm) / 2;
      // Re-anchor start time to maintain position
      _startTime = now - (_currentStepGlobal * newSecPerStep * 1000).round();
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
    print('▶️ Sequencer.play() called');
    if (isPlaying) return;
    isPlaying = true;
    _currentStepGlobal = 0;
    _startTime = DateTime.now().millisecondsSinceEpoch;
    _scheduleNextBeat();
  }

  void stop() {
    print('⏹️ Sequencer.stop() called');
    isPlaying = false;
    _timer?.cancel();
    _audioEngine.stopAll();
  }

  void _scheduleNextBeat() {
    if (!isPlaying) return;

    // 16 steps per measure (0-15)
    int stepIndex = _currentStepGlobal % 16;

    _playSoundsForStep(stepIndex);
    onStep(); // Notify UI

    _currentStepGlobal++;

    // Interval Calculation:
    // BPM is beats per minute. 1 Beat = one of the 8 counts.
    // We have 16 steps over 8 beats = 2 steps per beat.
    // Seconds per Step = (60 / BPM) / 2
    double secPerStep = (60.0 / bpm) / 2;
    int intervalMs = (secPerStep * 1000).round();

    int nextExpectedTime = _startTime + (_currentStepGlobal * intervalMs);
    int now = DateTime.now().millisecondsSinceEpoch;
    int waitTime = nextExpectedTime - now;

    // Drift correction: if lagging, execute immediately
    if (waitTime < 0) waitTime = 0;

    _timer = Timer(Duration(milliseconds: waitTime), _scheduleNextBeat);
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
        _audioEngine.playInstrument(instrument, volume: normalizedVolume);
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

        _audioEngine.playOneShot(
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
}
