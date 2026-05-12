// ignore_for_file: invalid_use_of_internal_member

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:five_six_seven_dance/audio/audio_engine.dart';

class FakeAudioBackend implements AudioBackend {
  final loaded = <String, AudioSource>{};
  final played = <String>[];
  final stopped = <SoundHandle>[];
  int nextHandleId = 1;
  bool initialized = false;

  @override
  bool get isInitialized => initialized;

  @override
  Future<void> init({
    required int bufferSize,
    required int sampleRate,
    required Channels channels,
  }) async {
    initialized = true;
  }

  @override
  Future<AudioSource> loadAsset(String path) async {
    final source = AudioSource(SoundHash.random());
    loaded[path] = source;
    return source;
  }

  @override
  Future<SoundHandle> play(AudioSource source, {double volume = 1.0}) async {
    played.add('${source.soundHash.hash}:$volume');
    final handle = SoundHandle(nextHandleId++);
    source.handlesInternal.add(handle);
    return handle;
  }

  @override
  Future<void> stop(SoundHandle handle) async {
    stopped.add(handle);
  }

  @override
  void setRelativePlaySpeed(SoundHandle handle, double speed) {}

  @override
  void deinit() {}
}

void main() {
  test('stopAll stops voice and instrument handles', () async {
    final backend = FakeAudioBackend();
    final engine = AudioEngine.test(backend: backend);

    await engine.loadBaseAssets();
    engine.playInstrument('Bass', volume: 0.75);
    engine.playOneShot('es_1', volume: 1);
    await Future<void>.delayed(Duration.zero);

    engine.stopAll();
    await Future<void>.delayed(Duration.zero);

    expect(backend.stopped.map((handle) => handle.id), containsAll([1, 2]));
  });

  test('playback queue applies backpressure when play calls pile up', () async {
    final backend = FakeAudioBackend();
    final engine = AudioEngine.test(backend: backend, maxPendingPlaybackTasks: 1);

    await engine.loadBaseAssets();
    engine.playInstrument('Bass');
    engine.playInstrument('Bongo');
    await Future<void>.delayed(Duration.zero);

    expect(backend.played, hasLength(1));
  });
}
