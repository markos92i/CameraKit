//
//  SystemPreferredCameraObserver.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 17/2/25.
//

import AVFoundation

/// Provides an async stream of device IDs representing the system-preferred camera.
///
/// Observing `AVCaptureDevice.systemPreferredCamera` requires class-level KVO (addObserver on the
/// type itself), which cannot use the closure-based `observe(_:options:changeHandler:)` API.
/// This helper encapsulates that pattern cleanly.
final class SystemPreferredCameraObserver: NSObject, Sendable {

    let changes: AsyncStream<String>
    private let continuation: AsyncStream<String>.Continuation

    override init() {
        let (changes, continuation) = AsyncStream.makeStream(of: String.self)
        self.changes = changes
        self.continuation = continuation
        super.init()
        AVCaptureDevice.self.addObserver(self, forKeyPath: "systemPreferredCamera", options: .new, context: nil)
    }

    deinit {
        AVCaptureDevice.self.removeObserver(self, forKeyPath: "systemPreferredCamera")
        continuation.finish()
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "systemPreferredCamera",
              let device = change?[.newKey] as? AVCaptureDevice else { return }
        continuation.yield(device.uniqueID)
    }
}
