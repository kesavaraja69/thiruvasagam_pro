import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks time-limited rewards earned by watching a rewarded ad.
///
/// Everything is persisted, so an unlock survives an app restart. A timer
/// notifies listeners when the next unlock expires so banners and settings
/// refresh without needing a relaunch.
class RewardUnlockService extends ChangeNotifier {
  RewardUnlockService._();

  static final RewardUnlockService instance = RewardUnlockService._();

  static const String _adFreeKey = 'reward_ad_free_until';
  static const String _fontsKey = 'reward_fonts_until';
  static const String _offlineKey = 'reward_offline_until';
  static const String _eyeProtectionKey = 'reward_eye_protection_until';

  static const Duration adFreeDuration = Duration(minutes: 60);
  static const Duration fontsDuration = Duration(hours: 24);
  static const Duration offlineDuration = Duration(hours: 24);
  static const Duration eyeProtectionDuration = Duration(days: 5);

  DateTime? _adFreeUntil;
  DateTime? _fontsUntil;
  DateTime? _offlineUntil;
  DateTime? _eyeProtectionUntil;
  Timer? _expiryTimer;

  DateTime? get adFreeUntil => _adFreeUntil;
  DateTime? get fontsUntil => _fontsUntil;
  DateTime? get offlineUntil => _offlineUntil;

  bool get isAdFree => _isActive(_adFreeUntil);
  bool get fontsUnlocked => _isActive(_fontsUntil);
  bool get offlineUnlocked => _isActive(_offlineUntil);
  bool get eyeProtectionEnabled => _isActive(_eyeProtectionUntil);

  Duration? get adFreeRemaining => _remaining(_adFreeUntil);
  Duration? get fontsRemaining => _remaining(_fontsUntil);
  Duration? get offlineRemaining => _remaining(_offlineUntil);
  Duration? get eyeProtectionRemaining => _remaining(_eyeProtectionUntil);

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _adFreeUntil = _readDate(prefs, _adFreeKey);
    _fontsUntil = _readDate(prefs, _fontsKey);
    _offlineUntil = _readDate(prefs, _offlineKey);
    _eyeProtectionUntil = _readDate(prefs, _eyeProtectionKey);
    _scheduleExpiry();
    notifyListeners();
  }

  Future<void> grantAdFree() async {
    _adFreeUntil = _extend(_adFreeUntil, adFreeDuration);
    await _save(_adFreeKey, _adFreeUntil!);
    _afterGrant();
  }

  Future<void> grantFonts() async {
    _fontsUntil = _extend(_fontsUntil, fontsDuration);
    await _save(_fontsKey, _fontsUntil!);
    _afterGrant();
  }

  Future<void> grantOffline() async {
    _offlineUntil = _extend(_offlineUntil, offlineDuration);
    await _save(_offlineKey, _offlineUntil!);
    _afterGrant();
  }

  Future<void> grantEyeProtection() async {
    _eyeProtectionUntil = _extend(_eyeProtectionUntil, eyeProtectionDuration);
    await _save(_eyeProtectionKey, _eyeProtectionUntil!);
    _afterGrant();
  }

  static bool _isActive(DateTime? until) =>
      until != null && DateTime.now().isBefore(until);

  static Duration? _remaining(DateTime? until) {
    if (!_isActive(until)) return null;
    return until!.difference(DateTime.now());
  }

  static DateTime _extend(DateTime? until, Duration duration) {
    final now = DateTime.now();
    final base = (until != null && until.isAfter(now)) ? until : now;
    return base.add(duration);
  }

  static DateTime? _readDate(SharedPreferences prefs, String key) {
    final millis = prefs.getInt(key);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> _save(String key, DateTime until) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, until.millisecondsSinceEpoch);
  }

  void _afterGrant() {
    _scheduleExpiry();
    notifyListeners();
  }

  void _scheduleExpiry() {
    _expiryTimer?.cancel();

    final now = DateTime.now();
    DateTime? next;
    for (final until in [
      _adFreeUntil,
      _fontsUntil,
      _offlineUntil,
      _eyeProtectionUntil,
    ]) {
      if (until != null && until.isAfter(now)) {
        if (next == null || until.isBefore(next)) next = until;
      }
    }

    if (next == null) return;

    _expiryTimer = Timer(next.difference(now) + const Duration(seconds: 1), () {
      notifyListeners();
      _scheduleExpiry();
    });
  }
}
