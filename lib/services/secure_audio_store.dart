import 'dart:io';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Stores downloaded songs encrypted at rest.
///
/// The AES-256 key lives in [FlutterSecureStorage] (Android Keystore / iOS
/// Keychain). Each file is encrypted with AES-CBC and a random IV, which is
/// prepended to the ciphertext. Playback decrypts to a private temporary file
/// that is removed when playback stops, so the user cannot open or copy the
/// downloaded media from a file manager.
class SecureAudioStore {
  SecureAudioStore._();

  static final SecureAudioStore instance = SecureAudioStore._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _keyName = 'secure_audio_aes_key_v1';
  static const int _ivLength = 16;

  enc.Key? _cachedKey;

  Future<enc.Key> _getKey() async {
    if (_cachedKey != null) return _cachedKey!;

    final stored = await _storage.read(key: _keyName);
    if (stored != null && stored.isNotEmpty) {
      _cachedKey = enc.Key.fromBase64(stored);
      return _cachedKey!;
    }

    final generated = enc.Key.fromSecureRandom(32);
    await _storage.write(key: _keyName, value: generated.base64);
    _cachedKey = generated;
    return generated;
  }

  String _fileName(String key) {
    final safe = key.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return 'song_$safe.enc';
  }

  Future<Directory> _encryptedDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/secure_audio');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _encryptedFile(String key) async {
    final dir = await _encryptedDirectory();
    return File('${dir.path}/${_fileName(key)}');
  }

  Future<bool> isDownloaded(String key) async {
    try {
      final file = await _encryptedFile(key);
      return await file.exists();
    } catch (e) {
      debugPrint('SecureAudioStore: isDownloaded failed: $e');
      return false;
    }
  }

  /// Downloads [url] and writes an encrypted copy. Returns false on failure.
  Future<bool> downloadAndEncrypt({
    required String key,
    required String url,
  }) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        debugPrint('SecureAudioStore: HTTP ${response.statusCode} for $url');
        return false;
      }

      final aesKey = await _getKey();
      final iv = enc.IV.fromSecureRandom(_ivLength);
      final encrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encryptBytes(response.bodyBytes, iv: iv);

      final target = await _encryptedFile(key);
      final temp = File('${target.path}.part');
      final sink = temp.openWrite();
      sink.add(iv.bytes);
      sink.add(encrypted.bytes);
      await sink.close();

      if (await target.exists()) await target.delete();
      await temp.rename(target.path);
      return true;
    } catch (e) {
      debugPrint('SecureAudioStore: download/encrypt failed: $e');
      return false;
    }
  }

  /// Decrypts the song into a private temp file for just_audio to play.
  /// The caller is responsible for deleting the returned file when playback
  /// stops or the chapter changes.
  Future<File?> decryptToTemp(String key) async {
    try {
      final source = await _encryptedFile(key);
      if (!await source.exists()) return null;

      final bytes = await source.readAsBytes();
      if (bytes.length <= _ivLength) return null;

      final iv = enc.IV(bytes.sublist(0, _ivLength));
      final cipherBytes = bytes.sublist(_ivLength);
      final aesKey = await _getKey();
      final encrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.cbc));
      final plain = encrypter.decryptBytes(enc.Encrypted(cipherBytes), iv: iv);

      final tempDirectory = Directory(
        '${(await getTemporaryDirectory()).path}/secure_playback',
      );
      if (!await tempDirectory.exists()) {
        await tempDirectory.create(recursive: true);
      }
      final output = File(
        '${tempDirectory.path}/${_fileName(key).replaceAll('.enc', '')}_${DateTime.now().millisecondsSinceEpoch}.mp3',
      );
      await output.writeAsBytes(plain, flush: true);
      return output;
    } catch (e) {
      // A wrong/missing key or corrupted file must not crash playback.
      debugPrint('SecureAudioStore: decrypt failed: $e');
      return null;
    }
  }

  Future<void> delete(String key) async {
    try {
      final file = await _encryptedFile(key);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('SecureAudioStore: delete failed: $e');
    }
  }

  Future<void> deleteTemp(File? file) async {
    if (file == null) return;
    try {
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('SecureAudioStore: temp cleanup failed: $e');
    }
  }

  /// Removes decrypted playback files left behind by a previous crash.
  Future<void> cleanupTempDirectory() async {
    try {
      final dir = Directory(
        '${(await getTemporaryDirectory()).path}/secure_playback',
      );
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (e) {
      debugPrint('SecureAudioStore: temp directory cleanup failed: $e');
    }
  }
}
