import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// A singleton service for caching audio files from the network.
/// Uses flutter_cache_manager under the hood with a custom cache key.
class AudioCacheService {
  AudioCacheService._();

  static final AudioCacheService instance = AudioCacheService._();

  /// Custom cache manager for audio files with longer retention.
  static final CacheManager _audioCacheManager = CacheManager(
    Config(
      'thiruvasagam_audio_cache',
      stalePeriod: const Duration(days: 30), // Keep files for 30 days
      maxNrOfCacheObjects: 100, // Max 100 cached audio files
    ),
  );

  /// Get the file for a given [url].
  /// Returns the local [File] if cached, otherwise downloads and caches it.
  /// Returns `null` if the download fails (e.g. no network).
  Future<File?> getCachedFile(String url) async {
    try {
      final file = await _audioCacheManager.getSingleFile(url);
      return file;
    } catch (e) {
      debugPrint('AudioCacheService: Error getting cached file: $e');
      return null;
    }
  }

  /// Returns the already-cached file without attempting a network download.
  /// Use this for offline playback: it never blocks on or requires a network.
  Future<File?> getExistingFile(String url) async {
    try {
      final fileInfo = await _audioCacheManager.getFileFromCache(url);
      return fileInfo?.file;
    } catch (e) {
      debugPrint('AudioCacheService: Error reading cached file: $e');
      return null;
    }
  }

  /// Check if a file is already cached for the given [url].
  Future<bool> isCached(String url) async {
    final fileInfo = await _audioCacheManager.getFileFromCache(url);
    return fileInfo != null;
  }

  /// Pre-cache a file in the background (does not return the file).
  Future<void> preCache(String url) async {
    try {
      await _audioCacheManager.downloadFile(url, force: false);
    } catch (e) {
      debugPrint('AudioCacheService: Error pre-caching file: $e');
    }
  }

  /// Get the local file path for a cached audio [url].
  /// Returns the file path string if cached, otherwise `null`.
  Future<String?> getCachedFilePath(String url) async {
    final file = await getCachedFile(url);
    return file?.path;
  }

  /// Remove a specific cached file by [url].
  Future<void> removeCachedFile(String url) async {
    await _audioCacheManager.removeFile(url);
  }

  /// Clear all cached audio files.
  Future<void> clearCache() async {
    await _audioCacheManager.emptyCache();
  }

  /// Format cache size for display (KB, MB, GB).
  String formatCacheSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
