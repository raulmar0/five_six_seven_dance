import 'dart:async';
import 'dart:js_interop';

@JS('pwa567')
external _PwaBridge? get _bridge;

@JS('document')
external _Document get _document;

extension type _PwaBridge._(JSObject _) implements JSObject {
  external bool canInstall();
  external bool isIOS();
  external bool isStandalone();
  external JSPromise<JSString?> install();
  external bool updateAvailable();
  external JSPromise<JSBoolean> checkForUpdate();
  external void applyUpdate();
}

extension type _Document._(JSObject _) implements JSObject {
  external void addEventListener(String type, JSFunction listener);
}

bool isIOSPlatform() => _bridge?.isIOS() ?? false;
bool isStandaloneMode() => _bridge?.isStandalone() ?? false;
bool canInstallNow() => _bridge?.canInstall() ?? false;
bool updateAvailableNow() => _bridge?.updateAvailable() ?? false;

void onInstallable(void Function() listener) {
  _document.addEventListener('pwa567:installable', ((JSAny _) => listener()).toJS);
}

void onInstalled(void Function() listener) {
  _document.addEventListener('pwa567:installed', ((JSAny _) => listener()).toJS);
}

void onUpdateAvailable(void Function() listener) {
  _document.addEventListener('pwa567:update-available', ((JSAny _) => listener()).toJS);
}

Future<String> triggerInstall() async {
  final bridge = _bridge;
  if (bridge == null) return 'unavailable';
  final jsResult = await bridge.install().toDart;
  return jsResult?.toDart ?? 'dismissed';
}

Future<void> checkForUpdate() async {
  final bridge = _bridge;
  if (bridge == null) return;
  await bridge.checkForUpdate().toDart;
}

void applyUpdate() {
  _bridge?.applyUpdate();
}
