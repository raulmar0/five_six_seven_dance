import 'package:flutter/foundation.dart';

import 'pwa_service_stub.dart' if (dart.library.js_interop) 'pwa_service_web.dart' as impl;

/// PWA install + update affordances. Backed by `web/pwa.js` on web; no-op on native.
class PwaService extends ChangeNotifier {
  PwaService._();

  static final PwaService instance = PwaService._().._init();

  bool _canInstall = false;
  bool _updateAvailable = false;
  bool _bannerDismissed = false;

  /// True if Chromium/Edge captured a `beforeinstallprompt` we can replay.
  bool get canInstall => _canInstall;

  /// True if iOS Safari — install via Add-to-Home-Screen, no native prompt.
  bool get isIOS => impl.isIOSPlatform();

  /// True when running inside the installed PWA.
  bool get isStandalone => impl.isStandaloneMode();

  /// True when a new service worker is waiting to activate.
  bool get updateAvailable => _updateAvailable;

  /// Show "install" affordances at all? (web + supported platform + not yet installed)
  bool get supportsInstall =>
      kIsWeb && !isStandalone && (canInstall || isIOS);

  /// Show the home-screen banner? (supports install AND user hasn't dismissed)
  bool get shouldShowBanner => supportsInstall && !_bannerDismissed;

  void _init() {
    if (!kIsWeb) return;
    _canInstall = impl.canInstallNow();
    _updateAvailable = impl.updateAvailableNow();
    impl.onInstallable(() {
      _canInstall = true;
      notifyListeners();
    });
    impl.onInstalled(() {
      _canInstall = false;
      _bannerDismissed = true;
      notifyListeners();
    });
    impl.onUpdateAvailable(() {
      _updateAvailable = true;
      notifyListeners();
    });
  }

  /// Triggers the install prompt on supported browsers. Returns the outcome string.
  Future<String> install() async {
    if (!kIsWeb) return 'unavailable';
    final result = await impl.triggerInstall();
    if (result == 'accepted') {
      _canInstall = false;
      _bannerDismissed = true;
      notifyListeners();
    }
    return result;
  }

  /// Dismiss the install banner for this session.
  void dismissBanner() {
    _bannerDismissed = true;
    notifyListeners();
  }

  /// Ask the service worker to check for an update.
  Future<void> checkForUpdate() async {
    if (!kIsWeb) return;
    await impl.checkForUpdate();
  }

  /// Apply a waiting service worker — page reloads when the new SW takes control.
  void applyUpdate() {
    if (!kIsWeb) return;
    impl.applyUpdate();
  }
}
