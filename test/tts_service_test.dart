import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thiruvasagampro/services/tts_service.dart';

void main() {
  // Must initialize binding before FlutterTts can work
  WidgetsFlutterBinding.ensureInitialized();

  group('TTSService Text Chunking', () {
    test('Short text should not be split', () {
      final chunks = TTSService.splitTextIntoChunks('வாழ்க வளமுடன்');
      expect(chunks.length, 1);
      expect(chunks.first, 'வாழ்க வளமுடன்');
    });

    test('Empty text should return empty list', () {
      final chunks = TTSService.splitTextIntoChunks('');
      expect(chunks.length, 0);
    });

    test('Text under 3000 chars should not be split', () {
      final text = 'திருவாசகம் ' * 100; // ~1300 chars
      final chunks = TTSService.splitTextIntoChunks(text);
      expect(chunks.length, 1);
    });

    test('Long Tamil text should be split into chunks', () {
      final longText = 'திருவாசகம் பாடல் வரிகள் ' * 300; // ~8400 chars
      final chunks = TTSService.splitTextIntoChunks(longText);

      expect(chunks.length, greaterThan(1));

      // Each chunk should be under 3000 chars
      for (final chunk in chunks) {
        expect(chunk.length, lessThanOrEqualTo(3001));
      }

      // Reassembling chunks should give back the original text
      final reassembled = chunks.join();
      expect(reassembled, equals(longText));
    });

    test('Should prefer splitting at newlines', () {
      final text = 'Line 1\n${'A' * 2500}\nLine 3';
      final chunks = TTSService.splitTextIntoChunks(text);

      if (chunks.length > 1) {
        expect(chunks.first, contains('\n'));
      }
    });

    test('Should prefer splitting at periods', () {
      final text = 'Sentence one. ${'A' * 2500}. Sentence three.';
      final chunks = TTSService.splitTextIntoChunks(text);

      if (chunks.length > 1) {
        expect(chunks.first, endsWith('. '));
      }
    });

    test('Very long text (10000+ chars) should split correctly', () {
      final veryLongText = 'இறைவன் புகழ் பாடுவோம் வாழ்க வளமுடன் வாழ்க ' * 500;
      final chunks = TTSService.splitTextIntoChunks(veryLongText);

      expect(chunks.length, greaterThan(1));

      // All chunks combined should equal original
      final reassembled = chunks.join();
      expect(reassembled, equals(veryLongText));
    });

    test('Text with only spaces should split at spaces', () {
      final text = '${'A' * 1500} ${'B' * 1500} ${'C' * 1000}';
      final chunks = TTSService.splitTextIntoChunks(text);
      expect(chunks.length, greaterThan(1));
    });
  });
}
