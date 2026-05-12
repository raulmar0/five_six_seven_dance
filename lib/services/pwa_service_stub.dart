// Non-web stub for PwaService. All methods are inert.

bool isIOSPlatform() => false;
bool isStandaloneMode() => false;
bool canInstallNow() => false;
bool updateAvailableNow() => false;

void onInstallable(void Function() listener) {}
void onInstalled(void Function() listener) {}
void onUpdateAvailable(void Function() listener) {}

Future<String> triggerInstall() async => 'unavailable';
Future<void> checkForUpdate() async {}
void applyUpdate() {}
