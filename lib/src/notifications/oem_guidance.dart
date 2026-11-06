/// OEM background-restriction guidance (see https://dontkillmyapp.com).
/// Static per-vendor steps shown in Settings → notification rescue.
/// Vendor matching uses [SystemBridge.manufacturer] (lowercase substring).
/// Kept in-app (no network) so the help works offline on the affected device.
class OemGuidance {
  final String vendor;
  final List<String> steps;

  const OemGuidance({required this.vendor, required this.steps});
}

const _genericSteps = [
  'Open Settings, then Apps, then This app, then Battery, and set it to Unrestricted / Not optimized.',
  'Turn off any background or battery restriction on the App Info page.',
  'Lock this app in your recent apps list so the system does not swipe it away.',
];

const _xiaomiSteps = [
  'Open Notifications below and enable show notifications, floating notifications, lock-screen notifications and sound.',
  'In that screen, open each channel (Reminders, Overdue) and set importance to High / Urgent.',
  'Open Settings, then Battery, then App battery saver, then this app, then No restrictions.',
  'Open Settings, then Apps, then Manage apps, then this app, then Enable Auto-start.',
  'Lock this app in recents (pull down on its card until the lock icon shows).',
];

const Map<String, OemGuidance> _byVendor = {
  'xiaomi': OemGuidance(
    vendor: 'XIAOMI / REDMI / POCO',
    steps: _xiaomiSteps,
  ),
  'redmi': OemGuidance(
    vendor: 'XIAOMI / REDMI / POCO',
    steps: _xiaomiSteps,
  ),
  'huawei': OemGuidance(
    vendor: 'HUAWEI / HONOR',
    steps: [
      'Open Settings, then Battery, then App launch, then this app, then Manage manually, and enable auto-launch, secondary launch and background running.',
      'Open Settings, then Apps, then This app, then Battery, and keep it running after screen off.',
      'Open Phone manager, then Battery, then Protected apps, and enable this app.',
      'Lock this app in recents.',
    ],
  ),
  'honor': OemGuidance(
    vendor: 'HUAWEI / HONOR',
    steps: [
      'Open Settings, then Battery, then App launch, then this app, then Manage manually, and enable auto-launch, secondary launch and background running.',
      'Open Settings, then Apps, then This app, then Battery, and keep it running after screen off.',
      'Lock this app in recents.',
    ],
  ),
  'oneplus': OemGuidance(
    vendor: 'ONEPLUS',
    steps: [
      'Open Settings, then Battery, then Battery optimization, then All apps, then this app, then Do Not Optimize.',
      'Open Settings, then Battery, then Advanced optimization, and disable deep / adaptive optimization for this app.',
      'LOCK THIS APP IN RECENTS — ONEPLUS REVERTS THE OPTIMIZATION SETTING OTHERWISE.',
      'Disable app auto-launch restrictions for this app where present.',
    ],
  ),
  'samsung': OemGuidance(
    vendor: 'SAMSUNG',
    steps: [
      'Open Settings, then Apps, then This app, then Battery, and set it to Unrestricted.',
      'Open Settings, then Battery, then Background usage limits, then Never sleeping apps, and add this app.',
      'Disable adaptive battery restrictions for this app if reminders go missing.',
      'Lock this app in recents.',
    ],
  ),
  'oppo': OemGuidance(
    vendor: 'OPPO / REALME',
    steps: [
      'Open Settings, then Battery, then App battery management, then this app, then allow background activity.',
      'Open Settings, then App management, then Auto-start management, and enable this app.',
      'Lock this app in recents.',
    ],
  ),
  'realme': OemGuidance(
    vendor: 'OPPO / REALME',
    steps: [
      'Open Settings, then Battery, then App battery management, then this app, then allow background activity.',
      'Open Settings, then App management, then Auto-start management, and enable this app.',
      'Lock this app in recents.',
    ],
  ),
  'vivo': OemGuidance(
    vendor: 'VIVO / IQOO',
    steps: [
      'Open Settings, then Battery, then Background power consumption, then this app, then allow.',
      'Open Settings, then More settings, then App manager, then Autostart, and enable this app.',
      'Lock this app in recents.',
    ],
  ),
  'nokia': OemGuidance(
    vendor: 'NOKIA (HMD)',
    steps: [
      'Open Settings, then Apps, then This app, then Battery, and set it to Unrestricted or Not optimized.',
      'DISABLE THE EVENWELL / POWER-SAVER SERVICES IF PRESENT ON YOUR MODEL.',
      'Lock this app in recents.',
    ],
  ),
  'hmd': OemGuidance(
    vendor: 'NOKIA (HMD)',
    steps: [
      'Open Settings, then Apps, then This app, then Battery, and set it to Unrestricted or Not optimized.',
      'DISABLE THE EVENWELL / POWER-SAVER SERVICES IF PRESENT ON YOUR MODEL.',
      'Lock this app in recents.',
    ],
  ),
};

/// Best-match guidance for [manufacturerLower] (already lowercased).
OemGuidance guidanceFor(String manufacturerLower) {
  for (final entry in _byVendor.entries) {
    if (manufacturerLower.contains(entry.key)) return entry.value;
  }
  final pretty = manufacturerLower.isEmpty
      ? 'YOUR DEVICE'
      : manufacturerLower.toUpperCase();
  return OemGuidance(vendor: pretty, steps: _genericSteps);
}
