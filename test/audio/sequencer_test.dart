import 'package:flutter_test/flutter_test.dart';
import 'package:five_six_seven_dance/audio/sequencer.dart';

class FakeClock implements SequencerClock {
  int elapsed = 0;
  bool started = false;

  @override
  int get elapsedMilliseconds => elapsed;

  @override
  void reset() {
    elapsed = 0;
  }

  @override
  void start() {
    started = true;
  }

  @override
  void stop() {
    started = false;
  }
}

class FakeScheduler implements SequencerScheduler {
  Duration? lastDelay;
  void Function()? _callback;
  bool cancelled = false;

  @override
  void schedule(Duration delay, void Function() callback) {
    cancelled = false;
    lastDelay = delay;
    _callback = callback;
  }

  @override
  void cancel() {
    cancelled = true;
    _callback = null;
  }

  void fire() {
    final callback = _callback;
    if (callback == null) {
      throw StateError('No callback scheduled');
    }
    callback();
  }
}

class FakePlayback implements SequencerPlayback {
  final instruments = <String>[];
  final voices = <String>[];
  bool stopped = false;

  @override
  void playInstrument(String instrumentKey, {double volume = 1.0}) {
    instruments.add(instrumentKey);
  }

  @override
  void playOneShot(String key, {double volume = 1.0, double speed = 1.0}) {
    voices.add(key);
  }

  @override
  void stopAll() {
    stopped = true;
  }
}

void main() {
  test('sequencer schedules from monotonic elapsed time and corrects drift', () {
    final clock = FakeClock();
    final scheduler = FakeScheduler();
    final playback = FakePlayback();
    final sequencer = Sequencer(
      onStep: () {},
      playback: playback,
      clock: clock,
      scheduler: scheduler,
    )
      ..setBpm(180)
      ..updateInstrumentVolumes({'Cowbell': 1, 'Guiro': 1});

    sequencer.play();

    expect(clock.started, isTrue);
    expect(scheduler.lastDelay, const Duration(milliseconds: 167));

    clock.elapsed = 190;
    scheduler.fire();

    expect(scheduler.lastDelay, const Duration(milliseconds: 143));
  });

  test('sequencer clamps late callbacks instead of scheduling negative delays', () {
    final clock = FakeClock();
    final scheduler = FakeScheduler();
    final sequencer = Sequencer(
      onStep: () {},
      playback: FakePlayback(),
      clock: clock,
      scheduler: scheduler,
    );

    sequencer.play();
    clock.elapsed = 1000;
    scheduler.fire();

    expect(scheduler.lastDelay, Duration.zero);
  });

  test('sequencer delegates playback synchronously and stops scheduler cleanly', () {
    final scheduler = FakeScheduler();
    final playback = FakePlayback();
    final sequencer = Sequencer(
      onStep: () {},
      playback: playback,
      clock: FakeClock(),
      scheduler: scheduler,
    )
      ..updateInstrumentVolumes({'Cowbell': 4, 'Guiro': 4})
      ..updateVoicePattern([true, false, false, false, false, false, false, false]);

    sequencer.play();
    sequencer.stop();

    expect(playback.instruments, ['Cowbell', 'Guiro']);
    expect(playback.voices, ['es_1']);
    expect(playback.stopped, isTrue);
    expect(scheduler.cancelled, isTrue);
  });
}
