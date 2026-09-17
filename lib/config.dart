/// Where the API lives.
///
/// Every service reads this instead of hardcoding a host, so there is one
/// place to change and no chance of a release build shipping with a
/// developer's laptop address in it.
///
/// Override at build time:
///
///   Android phone on your wifi:
///     flutter run --dart-define=API_BASE=http://192.168.1.42:8000
///
///   Android emulator (10.0.2.2 is how it reaches your machine):
///     flutter run --dart-define=API_BASE=http://10.0.2.2:8000
///
///   Release:
///     flutter build appbundle --dart-define=API_BASE=https://skillsforge360.org
class Api {
  /// The default is PRODUCTION on purpose.
  ///
  /// If someone forgets the flag on a release build, it should point at the
  /// live server — not at a laptop that will not be there.
  static const base = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://skillsforge360.org',
  );

  /// True when running against a local server. Used to show a small banner,
  /// so a build pointed at the wrong place is obvious rather than confusing.
  static bool get isLocal =>
      base.contains('192.168.') ||
      base.contains('10.0.2.2') ||
      base.contains('127.0.0.1') ||
      base.contains('localhost');
}
