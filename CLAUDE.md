# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is `file_share_intent`, a Flutter plugin that enables Flutter apps to receive sharing photos, videos, text, URLs, and other file types from other apps on both Android and iOS platforms. It's a fork of the original `receive_sharing_intent` plugin with additional merged pull requests and improvements.

**Key Features:**
- Cross-platform sharing support (Android SDK 19+, iOS 12.0+)
- Handles multiple media types: images, videos, text, files, PDFs, URLs
- iOS Share Extension with automatic app launching
- Stream-based API for real-time sharing events
- Video thumbnail and duration extraction
- Temporary file management with proper cleanup

## Development Commands

### Flutter Plugin Development
```bash
# Run example app (Android)
cd example && flutter run

# Run example app (iOS) 
cd example && flutter run -d ios

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format .

# Check pub dependencies
flutter pub deps

# Update dependencies
flutter pub upgrade
```

### Android-specific
```bash
# Build Android plugin
cd android && ./gradlew build

# Run Android tests
cd android && ./gradlew test
```

### iOS-specific
```bash
# Install CocoaPods dependencies
cd example/ios && pod install

# Build iOS from example
cd example && flutter build ios
```

## Architecture

### Core Components

**Platform Interface (`lib/file_share_intent.dart`)**
- Abstract `FileShareIntent` class defining the plugin contract
- `SharedMediaFile` data model with support for various media types
- Mock implementation for testing: `_FileShareIntentMock`

**Mobile Implementation (`lib/src/file_share_intent_mobile.dart`)**
- `FileShareIntentMobile` - concrete implementation using method/event channels
- Method channel: `file_share_intent/messages`
- Event channel: `file_share_intent/events-media`
- JSON-based data serialization for cross-platform communication

**Android Implementation (`android/src/main/kotlin/.../FileShareIntentPlugin.kt`)**
- Handles Android Intents: `ACTION_SEND`, `ACTION_SEND_MULTIPLE`, `ACTION_VIEW`
- File system integration using `FileDirectory.getAbsolutePath()`
- Video metadata extraction with `MediaMetadataRetriever`
- Thumbnail generation for video files
- Support for multiple MIME types and intent filters

**iOS Implementation (`ios/Classes/SwiftListenSharingIntentPlugin.swift`)**
- App Group-based data sharing between main app and Share Extension
- URL scheme handling with custom prefix validation
- Integration with Photos framework for asset access
- UserDefaults for inter-app communication
- Deep linking support via `application(_:open:options:)`

**iOS Share Extension (`ios/Classes/RSIShareViewController.swift`)**
- `RSIBaseShareViewController` - NEW UIViewController-based class for seamless sharing (bypasses compose dialog)
- `RSIShareViewController` - LEGACY SLComposeServiceViewController-based class (shows compose dialog)
- Handles multiple attachment types through `NSItemProvider`
- Configurable UI options: invisible, minimal spinner, or custom
- Automatic redirection to host app (configurable via `shouldAutoRedirect()`)
- Temporary file management in shared app group container
- Video thumbnail generation using `AVAssetImageGenerator`

### Data Flow

1. **Initial Share**: External app shares content → Platform native code processes intent → Data stored in shared location
2. **App Launch**: Plugin checks for initial shared data via `getInitialMedia()`
3. **Runtime Sharing**: New shares trigger event stream via `getMediaStream()`
4. **File Management**: Temporary copies created in app-specific cache directories
5. **Cleanup**: Use `reset()` to clear processed sharing data

### Platform-Specific Setup

**Android Configuration:**
- Intent filters in `AndroidManifest.xml` for different MIME types
- Permissions: `READ_EXTERNAL_STORAGE`
- Launch mode: `singleTask` recommended

**iOS Configuration:**
- Share Extension target creation in Xcode
- App Groups capability for data sharing
- Info.plist configuration for supported media types
- Custom URL scheme registration
- Build phases configuration for extension embedding

## Plugin Development Notes

### Testing
- Mock implementation available via `FileShareIntent.setMockValues()`
- Unit tests in `test/` directory
- Example app demonstrates all functionality

### Platform Compatibility
- Android: API 19+ (KitKat), Kotlin 1.9.22, Java 17
- iOS: 12.0+, Swift 5.0
- Flutter: 3.24.0+, Dart SDK: 3.6.0+

### Common Integration Tasks
- Configure intent filters for desired MIME types
- Set up iOS Share Extension with proper Info.plist
- Implement App Groups for iOS data sharing
- Choose between seamless sharing (`RSIBaseShareViewController`) vs compose dialog (`RSIShareViewController`)
- Handle temporary file cleanup in consuming apps
- Test sharing from various external apps (Photos, Files, Safari, etc.)

## Share Extension Implementation Options

### Option 1: Seamless Sharing (NEW - No Compose Dialog)
Use `RSIBaseShareViewController` for WhatsApp-style seamless sharing:

```swift
import file_share_intent

class SeamlessShareViewController: RSIBaseShareViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure seamless sharing
        showUI = true          // Show minimal loading indicator
        processingMessage = "Sharing..."
        autoRedirect = true    // Automatically redirect after processing
    }
    
    // Optional: Custom behavior after processing
    override func onAttachmentsProcessed() {
        // Custom logic here
        super.onAttachmentsProcessed()
    }
}
```

### Option 2: Traditional Compose Dialog (LEGACY)
Use `RSIShareViewController` for traditional sharing with compose dialog:

```swift
import file_share_intent

class ShareViewController: RSIShareViewController {
    override func shouldAutoRedirect() -> Bool {
        return false  // Allow user to add message before sharing
    }
    
    override func presentationAnimationDidFinish() {
        super.presentationAnimationDidFinish()
        navigationController?.navigationBar.topItem?.rightBarButtonItem?.title = "Send"
    }
}
```

### Configuration Options

**RSIBaseShareViewController Properties:**
- `showUI: Bool` - Show minimal processing UI or go invisible (default: false)
- `processingMessage: String` - Custom loading message (default: "Processing...")
- `autoRedirect: Bool` - Immediate redirect after processing (default: true)

**Override Points:**
- `shouldAutoRedirect() -> Bool` - Control automatic app redirection
- `onAttachmentsProcessed()` - Custom behavior when autoRedirect is false

### Build System
- Android: Gradle 8.4.1, Android Gradle Plugin
- iOS: CocoaPods integration, Xcode project configuration
- Plugin platforms defined in `pubspec.yaml` under `flutter.plugin`