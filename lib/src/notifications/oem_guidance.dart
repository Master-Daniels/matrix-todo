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
  'SETTINGS → APPS → THIS APP → BATTERY → SET TO UNRESTRICTED / NOT OPTIMIZED.',
  'DISABLE ANY BACKGROUND RESTRICTION / BACKGROUND LIMIT OPTION ON THE APP INFO PAGE.',
  'LOCK THIS APP IN THE RECENT-APPS LIST SO THE SYSTEM DOES NOT SWIPE IT AWAY.',
];

const _xiaomiSteps = [
  'TAP “NOTIFICATIONS” BELOW → ENABLE SHOW NOTIFICATIONS, FLOATING NOTIFICATIONS, LOCK-SCREEN NOTIFICATIONS AND SOUND.',
  'IN THE SAME SCREEN, OPEN EACH CHANNEL (REMINDERS, OVERDUE) AND SET IMPORTANCE TO HIGH/URGENT.',
  'SETTINGS → BATTERY → APP BATTERY SAVER → THIS APP → NO RESTRICTIONS.',
  'SETTINGS → APPS → MANAGE APPS → THIS APP → AUTOSTART → ENABLE.',
  'LOCK THIS APP IN RECENTS (PULL DOWN ON ITS CARD UNTIL THE LOCK ICON SHOWS).',
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
      'SETTINGS → BATTERY → APP LAUNCH → THIS APP → MANAGE MANUALLY: ENABLE AUTO-LAUNCH, SECONDARY LAUNCH, RUN IN BACKGROUND.',
      'SETTINGS → APPS → THIS APP → BATTERY → KEEP RUNNING AFTER SCREEN OFF.',
      'PHONE MANAGER → BATTERY → PROTECTED APPS → ENABLE THIS APP.',
      'LOCK THIS APP IN RECENTS.',
    ],
  ),
  'honor': OemGuidance(
    vendor: 'HUAWEI / HONOR',
    steps: [
      'SETTINGS → BATTERY → APP LAUNCH → THIS APP → MANAGE MANUALLY: ENABLE AUTO-LAUNCH, SECONDARY LAUNCH, RUN IN BACKGROUND.',
      'SETTINGS → APPS → THIS APP → BATTERY → KEEP RUNNING AFTER SCREEN OFF.',
      'LOCK THIS APP IN RECENTS.',
    ],
  ),
  'oneplus': OemGuidance(
    vendor: 'ONEPLUS',
    steps: [
      'SETTINGS → BATTERY → BATTERY OPTIMIZATION → ALL APPS → THIS APP → DON’T OPTIMIZE.',
      'SETTINGS → BATTERY → ADVANCED OPTIMIZATION → DISABLE DEEP / ADAPTIVE OPTIMIZATION FOR THIS APP.',
      'LOCK THIS APP IN RECENTS — ONEPLUS REVERTS THE OPTIMIZATION SETTING OTHERWISE.',
      'DISABLE APP AUTO-LAUNCH RESTRICTIONS FOR THIS APP WHERE PRESENT.',
    ],
  ),
  'samsung': OemGuidance(
    vendor: 'SAMSUNG',
    steps: [
      'SETTINGS → APPS → THIS APP → BATTERY → UNRESTRICTED.',
      'SETTINGS → BATTERY → BACKGROUND USAGE LIMITS → NEVER SLEEPING APPS → ADD THIS APP.',
      'DISABLE ADAPTIVE BATTERY RESTRICTIONS FOR THIS APP IF REMINDERS GO MISSING.',
      'LOCK THIS APP IN RECENTS.',
    ],
  ),
  'oppo': OemGuidance(
    vendor: 'OPPO / REALME',
    steps: [
      'SETTINGS → BATTERY → APP BATTERY MANAGEMENT → THIS APP → ALLOW BACKGROUND ACTIVITY.',
      'SETTINGS → APP MANAGEMENT → AUTO-START MANAGEMENT → ENABLE THIS APP.',
      'LOCK THIS APP IN RECENTS.',
    ],
  ),
  'realme': OemGuidance(
    vendor: 'OPPO / REALME',
    steps: [
      'SETTINGS → BATTERY → APP BATTERY MANAGEMENT → THIS APP → ALLOW BACKGROUND ACTIVITY.',
      'SETTINGS → APP MANAGEMENT → AUTO-START MANAGEMENT → ENABLE THIS APP.',
      'LOCK THIS APP IN RECENTS.',
    ],
  ),
  'vivo': OemGuidance(
    vendor: 'VIVO / IQOO',
    steps: [
      'SETTINGS → BATTERY → BACKGROUND POWER CONSUMPTION → THIS APP → ALLOW.',
      'SETTINGS → MORE SETTINGS → APP MANAGER → AUTOSTART → ENABLE THIS APP.',
      'LOCK THIS APP IN RECENTS.',
    ],
  ),
  'nokia': OemGuidance(
    vendor: 'NOKIA (HMD)',
    steps: [
      'SETTINGS → APPS → THIS APP → BATTERY → UNRESTRICTED / DON’T OPTIMIZE.',
      'DISABLE THE EVENWELL / POWER-SAVER SERVICES IF PRESENT ON YOUR MODEL.',
      'LOCK THIS APP IN RECENTS.',
    ],
  ),
  'hmd': OemGuidance(
    vendor: 'NOKIA (HMD)',
    steps: [
      'SETTINGS → APPS → THIS APP → BATTERY → UNRESTRICTED / DON’T OPTIMIZE.',
      'DISABLE THE EVENWELL / POWER-SAVER SERVICES IF PRESENT ON YOUR MODEL.',
      'LOCK THIS APP IN RECENTS.',
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
