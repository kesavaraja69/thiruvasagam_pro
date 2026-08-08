import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _isPaused = false;
  double _speechRate = 0.5;
  double _pitch = 1.0;
  double _volume = 1.0;
  String _currentVoice = '';
  List<Map<String, String>> _availableVoices = [];

  // FIX #1: Reference counting to prevent singleton disposal race
  int _referenceCount = 0;

  // FIX #3: Generation counter to invalidate orphaned chunk chains
  int _speakGeneration = 0;

  // Track text for resume fix
  String _lastSpokenText = '';

  // Getters
  bool get isSpeaking => _isSpeaking;
  bool get isPaused => _isPaused;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;
  String get currentVoice => _currentVoice;
  List<Map<String, String>> get availableVoices => _availableVoices;

  // Callbacks
  VoidCallback? onSpeechStart;
  VoidCallback? onSpeechComplete;
  Function(String)? onSpeechError;
  VoidCallback? onVoicesLoaded;
  Function(String)? onInitError;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set language to Tamil (India)
      await _flutterTts.setLanguage("ta-IN");

      // Check if Tamil is available
      bool isTamilAvailable = await _flutterTts.isLanguageAvailable("ta-IN");
      if (!isTamilAvailable) {
        debugPrint("Tamil language not available, using default language");
        await _flutterTts.setLanguage("en-US");
      }

      // Configure speech settings
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(_volume);
      await _flutterTts.setPitch(_pitch);

      // Load available voices
      await _loadVoices();

      // Set up handlers
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        _isPaused = false;
        onSpeechStart?.call();
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _isPaused = false;
        onSpeechComplete?.call();
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        _isPaused = false;
        onSpeechError?.call(msg);
        debugPrint("TTS Error: $msg");
      });

      _flutterTts.setPauseHandler(() {
        _isPaused = true;
      });

      _flutterTts.setContinueHandler(() {
        _isPaused = false;
      });

      _isInitialized = true;
      debugPrint("TTS Service initialized successfully");
    } catch (e) {
      debugPrint("Failed to initialize TTS: $e");
      onInitError?.call(e.toString());
    }
  }

  // Track chunks for long text
  List<String> _textChunks = [];
  int _currentChunkIndex = 0;
  bool _isSpeakingChunks = false;

  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (text.isEmpty) return;

    // Stop any current speech and invalidate old chunk chains
    if (_isSpeaking) {
      await stop();
    }

    try {
      // FIX #3: Increment generation to invalidate any orphaned chunk chains
      _speakGeneration++;
      final int currentGeneration = _speakGeneration;

      _lastSpokenText = text;
      _textChunks = splitTextIntoChunks(text);
      _currentChunkIndex = 0;
      _isSpeakingChunks = _textChunks.length > 1;

      if (_isSpeakingChunks) {
        // Set up chunk completion handler
        _flutterTts.setCompletionHandler(() {
          _isSpeaking = false;
          _isPaused = false;
          // FIX #3: Only continue if this is still the current generation
          if (currentGeneration == _speakGeneration) {
            _speakNextChunk(currentGeneration);
          }
          // Don't call onSpeechComplete until all chunks are done
        });
      }

      await _flutterTts.speak(_textChunks.first);
    } catch (e) {
      debugPrint("Error speaking text: $e");
      onSpeechError?.call(e.toString());
    }
  }

  Future<void> _speakNextChunk(int generation) async {
    // FIX #3: If generation changed, this chain is orphaned — stop
    if (generation != _speakGeneration) return;

    _currentChunkIndex++;
    if (_currentChunkIndex < _textChunks.length) {
      _isSpeaking = true;
      await _flutterTts.speak(_textChunks[_currentChunkIndex]);
    } else {
      // All chunks finished
      _isSpeakingChunks = false;
      _textChunks = [];
      _currentChunkIndex = 0;
      // Restore original completion handler
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _isPaused = false;
        onSpeechComplete?.call();
      });
      onSpeechComplete?.call();
    }
  }

  /// Splits text into chunks of ~3000 characters at sentence/line boundaries
  static List<String> splitTextIntoChunks(String text) {
    const int maxChunkSize = 3000;

    if (text.isEmpty) return [];
    if (text.length <= maxChunkSize) return [text];

    List<String> chunks = [];
    String remaining = text;

    while (remaining.isNotEmpty) {
      if (remaining.length <= maxChunkSize) {
        chunks.add(remaining);
        break;
      }

      // Find a good break point (newline, period, or space)
      int breakIndex = remaining.lastIndexOf('\n', maxChunkSize);
      if (breakIndex <= 0) {
        breakIndex = remaining.lastIndexOf('. ', maxChunkSize);
      }
      if (breakIndex <= 0) {
        breakIndex = remaining.lastIndexOf(' ', maxChunkSize);
      }
      if (breakIndex <= 0) {
        breakIndex = maxChunkSize;
      } else {
        breakIndex += 1;
      }

      chunks.add(remaining.substring(0, breakIndex));
      remaining = remaining.substring(breakIndex).trimLeft();
    }

    return chunks;
  }

  Future<void> pause() async {
    if (_isSpeaking && !_isPaused) {
      await _flutterTts.pause();
    }
  }

  Future<void> resume() async {
    // FIX #2: speak("") doesn't work on Android — re-speak the text
    if (_isPaused) {
      _isPaused = false;
      // Re-speak the current chunk (or remaining text)
      if (_isSpeakingChunks && _currentChunkIndex < _textChunks.length) {
        await _flutterTts.speak(_textChunks[_currentChunkIndex]);
      } else if (_lastSpokenText.isNotEmpty) {
        await _flutterTts.speak(_lastSpokenText);
      }
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
    _isPaused = false;
    _isSpeakingChunks = false;
    _textChunks = [];
    _currentChunkIndex = 0;
    // FIX #3: Invalidate any orphaned chunk chains
    _speakGeneration++;
    // Restore original completion handler
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _isPaused = false;
      onSpeechComplete?.call();
    });
  }

  Future<void> _loadVoices() async {
    try {
      dynamic voices = await _flutterTts.getVoices;
      if (voices is List) {
        _availableVoices = voices
            .where((v) => v['locale']?.toString().startsWith('ta') == true)
            .map<Map<String, String>>((v) => {
                  'name': v['name']?.toString() ?? '',
                  'locale': v['locale']?.toString() ?? '',
                })
            .toList();

        // If no Tamil voices, show all available voices
        if (_availableVoices.isEmpty) {
          _availableVoices = voices
              .map<Map<String, String>>((v) => {
                    'name': v['name']?.toString() ?? '',
                    'locale': v['locale']?.toString() ?? '',
                  })
              .toList();
        }

        if (_availableVoices.isNotEmpty) {
          _currentVoice = _availableVoices.first['name']!;
        }
        debugPrint("Loaded ${_availableVoices.length} voices");
      }
      onVoicesLoaded?.call();
    } catch (e) {
      debugPrint("Error loading voices: $e");
      onVoicesLoaded?.call();
    }
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    await _flutterTts.setSpeechRate(_speechRate);
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _flutterTts.setPitch(_pitch);
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _flutterTts.setVolume(_volume);
  }

  Future<void> setVoice(Map<String, String> voice) async {
    try {
      await _flutterTts.setVoice({"name": voice['name']!, "locale": voice['locale']!});
      _currentVoice = voice['name']!;
    } catch (e) {
      debugPrint("Error setting voice: $e");
    }
  }

  void clearCallbacks() {
    onSpeechStart = null;
    onSpeechComplete = null;
    onSpeechError = null;
    onVoicesLoaded = null;
    onInitError = null;
  }

  // FIX #1: Reference-counted disposal
  void acquire() {
    _referenceCount++;
  }

  void release() {
    _referenceCount--;
    if (_referenceCount <= 0) {
      _referenceCount = 0;
      _isInitialized = false;
    }
  }

  Future<void> dispose() async {
    await stop();
    clearCallbacks();
    release();
  }
}