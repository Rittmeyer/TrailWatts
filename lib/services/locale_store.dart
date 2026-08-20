import 'package:flutter/widgets.dart';

/// Which language the interface is in.
///
/// The app followed the device and offered no way to disagree with it, which
/// is wrong for the rider on a shared or borrowed phone, and for anyone whose
/// device language is not the one they read training in. `null` still means
/// "follow the device" - it stays the default, it is just no longer the only
/// option.
///
/// Like every other store here, this lives in memory: the choice holds for
/// the session and comes back to the device language on a fresh start.
class LocaleStore extends ChangeNotifier {
  LocaleStore._();

  static final LocaleStore instance = LocaleStore._();

  Locale? _locale;

  /// The chosen language, or null while the app follows the device.
  Locale? get locale => _locale;

  bool get followsDevice => _locale == null;

  /// The languages offered, in the order they are shown. `null` is the
  /// device-following entry and comes first, because it is the default.
  static const options = <Locale?>[null, Locale('pt'), Locale('en')];

  void use(Locale? locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }
}
