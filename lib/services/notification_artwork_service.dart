import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

/// Exposes the app logo as a `file://` URI for the media notification.
///
/// `audio_service` (used by `just_audio_background`) only accepts file,
/// network, or content URIs for `MediaItem.artUri`, not Flutter asset paths.
/// The bundled logo is copied once to the app support directory so the
/// notification shows the Thiruvasagam icon instead of the default Flutter
/// artwork.
class NotificationArtworkService {
  NotificationArtworkService._();

  static const String _assetPath = 'assets/icons/logo1.png';
  static Uri? _artUri;

  /// `null` when the artwork could not be prepared; the notification then
  /// falls back to its default.
  static Uri? get artUri => _artUri;

  static Future<void> prepare() async {
    try {
      final directory = await getApplicationSupportDirectory();
      final file = File('${directory.path}/notification_artwork.png');

      if (!await file.exists() || await file.length() == 0) {
        final data = await rootBundle.load(_assetPath);
        await file.create(recursive: true);
        await file.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
      }

      _artUri = file.uri;
    } catch (error) {
      debugPrint('Notification artwork unavailable: $error');
    }
  }
}
