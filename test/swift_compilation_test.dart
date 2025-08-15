import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  group('Swift Compilation Tests', () {
    test('SwiftListenSharingIntentPlugin.swift compiles without errors',
        () async {
      final swiftFile = File(
          'ios/file_share_intent/Sources/file_share_intent/SwiftListenSharingIntentPlugin.swift');
      expect(swiftFile.existsSync(), true, reason: 'Swift file should exist');

      // Check for Photos framework usage (should be none)
      final content = await swiftFile.readAsString();
      expect(content.contains('import Photos'), false,
          reason: 'Should not import Photos framework');
      expect(content.contains('PHAsset'), false,
          reason: 'Should not use PHAsset');
      expect(content.contains('PHImageManager'), false,
          reason: 'Should not use PHImageManager');
      expect(content.contains('PHContentEditingInputRequestOptions'), false,
          reason: 'Should not use Photos APIs');

      // Verify required imports are present
      expect(content.contains('import Flutter'), true,
          reason: 'Should import Flutter');
      expect(content.contains('import UIKit'), true,
          reason: 'Should import UIKit');
      expect(content.contains('import UniformTypeIdentifiers'), true,
          reason: 'Should import UniformTypeIdentifiers');

      // Run Swift syntax check
      final result = await Process.run(
          'swiftc',
          [
            '-parse',
            swiftFile.path,
          ],
          workingDirectory: Directory.current.path);

      expect(result.exitCode, 0,
          reason: 'Swift compilation should succeed. Errors: ${result.stderr}');
    });

    test('RSIShareViewController.swift compiles without errors', () async {
      final swiftFile = File(
          'ios/file_share_intent/Sources/file_share_intent/RSIShareViewController.swift');
      expect(swiftFile.existsSync(), true, reason: 'Swift file should exist');

      // Check for Photos framework usage (should be none)
      final content = await swiftFile.readAsString();
      expect(content.contains('import Photos'), false,
          reason: 'Should not import Photos framework');
      expect(content.contains('PHAsset'), false,
          reason: 'Should not use PHAsset');

      // Verify required imports are present
      expect(content.contains('import UIKit'), true,
          reason: 'Should import UIKit');
      expect(content.contains('import Social'), true,
          reason: 'Should import Social');

      // Run Swift syntax check
      final result = await Process.run(
          'swiftc',
          [
            '-parse',
            swiftFile.path,
          ],
          workingDirectory: Directory.current.path);

      expect(result.exitCode, 0,
          reason: 'Swift compilation should succeed. Errors: ${result.stderr}');
    });

    test('Classes directory Swift files compile without errors', () async {
      final swiftFile1 =
          File('ios/Classes/SwiftListenSharingIntentPlugin.swift');
      final swiftFile2 = File('ios/Classes/RSIShareViewController.swift');

      expect(swiftFile1.existsSync(), true,
          reason: 'Classes SwiftListenSharingIntentPlugin.swift should exist');
      expect(swiftFile2.existsSync(), true,
          reason: 'Classes RSIShareViewController.swift should exist');

      // Check both files for Photos framework usage (should be none)
      for (final file in [swiftFile1, swiftFile2]) {
        final content = await file.readAsString();
        expect(content.contains('import Photos'), false,
            reason: '${file.path} should not import Photos framework');
        expect(content.contains('PHAsset'), false,
            reason: '${file.path} should not use PHAsset');
      }

      // Run Swift syntax check on both files
      for (final file in [swiftFile1, swiftFile2]) {
        final result = await Process.run(
            'swiftc',
            [
              '-parse',
              file.path,
            ],
            workingDirectory: Directory.current.path);

        expect(result.exitCode, 0,
            reason:
                'Swift compilation should succeed for ${file.path}. Errors: ${result.stderr}');
      }
    });
  });
}
