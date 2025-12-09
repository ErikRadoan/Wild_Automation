import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Service for OCR (Optical Character Recognition)
class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract text from an image file
  Future<String> extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      return recognizedText.text;
    } catch (e) {
      throw Exception('OCR failed: $e');
    }
  }

  /// Extract text from a screen region
  /// Takes a screenshot of the region and performs OCR
  Future<String> extractTextFromRegion({
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    try {
      // Take screenshot of the region
      // Note: This requires platform-specific implementation
      // For now, we'll use a temporary approach

      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/ocr_region_${DateTime.now().millisecondsSinceEpoch}.png');

      // Screenshot would be taken here using screen_capturer
      // For Python integration, we'll pass coordinates to Python

      throw UnimplementedError('Use Python API for screen region OCR');
    } catch (e) {
      throw Exception('Region OCR failed: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer.close();
  }

  /// Get text blocks with positions
  Future<List<TextBlock>> extractTextBlocks(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      return recognizedText.blocks;
    } catch (e) {
      throw Exception('Text block extraction failed: $e');
    }
  }
}

/// Simple wrapper for text extraction results
class OCRResult {
  final String text;
  final double confidence;
  final List<TextBlock> blocks;

  const OCRResult({
    required this.text,
    required this.confidence,
    required this.blocks,
  });
}

