import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PosterGeneratorService {
  /// Captures any widget wrapped in a [RepaintBoundary] identified by [boundaryKey]
  /// and returns high-resolution PNG bytes (default 3.0x pixel ratio for 1080p+ output).
  static Future<Uint8List?> capturePng(
    GlobalKey boundaryKey, {
    double pixelRatio = 3.0,
  }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[PosterGenerator] Error capturing widget to PNG: $e');
      return null;
    }
  }

  /// Saves the captured PNG to a temporary file and opens the native OS share sheet
  /// sharing both the visual poster image AND the pre-written caption with the donation link.
  static Future<bool> sharePosterWithLink({
    required Uint8List pngBytes,
    required String filename,
    required String shareMessage,
    String? subject,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final sanitizedFilename = filename.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final filePath = '${tempDir.path}/$sanitizedFilename.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      final xFile = XFile(file.path, mimeType: 'image/png');
      final result = await Share.shareXFiles(
        [xFile],
        text: shareMessage,
        subject: subject ?? 'Support this Campaign',
      );

      return result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed;
    } catch (e) {
      debugPrint('[PosterGenerator] Error sharing poster: $e');
      return false;
    }
  }

  /// Downloads and saves the PNG file to the device's documents / cache directory.
  static Future<String?> downloadPoster({
    required Uint8List pngBytes,
    required String filename,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final sanitizedFilename = filename.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final filePath = '${appDir.path}/$sanitizedFilename.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);
      return file.path;
    } catch (e) {
      debugPrint('[PosterGenerator] Error saving poster: $e');
      return null;
    }
  }
}
