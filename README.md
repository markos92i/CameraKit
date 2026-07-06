# CameraKit

![Swift 6.3](https://img.shields.io/badge/Swift-6.3-F05138?logo=swift&logoColor=white)
![iOS 18+](https://img.shields.io/badge/iOS-18%2B-007AFF)
![SPM](https://img.shields.io/badge/SPM-Compatible-blue)
![No Dependencies](https://img.shields.io/badge/Dependencies-None-green)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow)

A full-featured SwiftUI camera framework built on modern concurrency. Photo capture, video recording, real-time preview with filters, rectangle/text detection, HDR, Live Photos, Camera Control (iPhone 16+), and focus/exposure tap — all driven by an `@Observable` model.

## Features

- **SwiftUI-native** — `@Observable` camera model binds directly to your views
- **Photo & Video capture** — With quality prioritization and Live Photo support
- **HDR video** — 10-bit HDR recording when supported
- **Real-time preview** — `AsyncStream<CIImage>` for custom processing pipelines
- **Image filters** — Rectangle detection (cards/documents) and text recognition via Vision
- **Camera Control** — Native support for iPhone 16+ hardware button (zoom slider, filter picker)
- **Focus & Exposure** — Tap-to-focus with animated indicator
- **Device switching** — Front/back/external camera toggle
- **Rotation handling** — Automatic orientation via `AVCaptureDevice.RotationCoordinator`
- **Actor-based capture** — `CaptureService` runs entirely off-main-thread for smooth UI
- **Strict concurrency** — Compiles with `-strict-concurrency=complete`

## Installation

Add CameraKit to your project via Swift Package Manager:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/markos92i/CameraKit.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** → paste the repository URL.

## Quick Start

```swift
import CameraKit

struct CameraScreen: View {
    @State var camera = CameraModel()

    var body: some View {
        CameraPreview(source: camera.preview)
            .task { await camera.start() }
            .overlay(alignment: .bottom) {
                Button("Capture") {
                    Task { let photo = await camera.capturePhoto() }
                }
            }
    }
}
```

## Camera Model

`CameraModel` is the main interface — an `@Observable @MainActor` class that mediates between your SwiftUI views and the capture pipeline:

```swift
let camera = CameraModel(configuration: CameraConfiguration(
    captureMode: .photo,
    qualityPrioritization: .quality,
    isLivePhotoEnabled: true,
    isHDRVideoEnabled: false,
    savesToGallery: true
))

// Start
await camera.start()

// Capture photo
let photo = await camera.capturePhoto()

// Record video
let movie = await camera.toggleRecording()  // start
let movie = await camera.toggleRecording()  // stop → returns Movie

// Switch camera
await camera.switchVideoDevices()

// Focus & expose at point
await camera.focusAndExpose(at: CGPoint(x: 0.5, y: 0.5))

// Stop
await camera.stop()
```

## Capture Modes

```swift
// Photo mode (default)
camera.captureMode = .photo

// Video mode
camera.captureMode = .video
```

## Image Filters (Real-time)

Built-in Vision-powered filters that process the live preview stream:

```swift
// Rectangle detection (cards, IDs, documents)
camera.imageFilter = .cards

// Text recognition
camera.imageFilter = .text

// No filter
camera.imageFilter = .none
```

Detected features are exposed via `camera.featureMetadata` for overlay rendering.

## States & UI Binding

The model exposes reactive state for building responsive UIs:

```swift
camera.status            // .unknown, .unauthorized, .running, .failed
camera.captureActivity   // .idle, .photoCapture, .movieCapture
camera.isSwitchingDevices
camera.isSwitchingModes
camera.isProcessing
camera.shouldFlashScreen // flash animation trigger
camera.thumbnail         // last capture thumbnail (CGImage)
camera.lastPhoto         // last captured UIImage
camera.lastVideo         // last recorded video URL
camera.focusPoints       // active focus indicators for overlay
```

## Architecture

```
CameraKit/
├── CameraModel.swift        — @Observable @MainActor public interface
├── CaptureService.swift     — Actor-based capture pipeline (off main thread)
├── PreviewCameraModel.swift — Mock model for SwiftUI Previews & Simulator
├── Capture/                 — PhotoCapture, MovieCapture, PreviewCapture
├── Controls/                — Camera Control (iPhone 16+ hardware button)
├── Model/                   — CameraState, CaptureMode, ImageFilter, Photo, Movie
├── Overlays/                — Focus indicators, feature metadata overlays
├── Recognition/             — Vision-based rectangle & text detection
├── Views/                   — CameraPreview, capture UI components
├── Toolbars/                — Camera toolbar views
└── Utils/                   — Device lookup, media library, extensions
```

## Requirements

| Requirement | Version |
|------------|---------|
| Swift | 6.3+ |
| iOS | 18.0+ |
| Xcode | 26+ |

> Note: CameraKit requires a physical device for camera functionality. Use `PreviewCameraModel` for SwiftUI Previews and Simulator.

## License

CameraKit is available under the MIT license. See the [LICENSE](LICENSE) file for details.
