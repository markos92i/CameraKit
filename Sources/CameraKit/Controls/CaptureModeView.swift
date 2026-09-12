//
//  CaptureModeView.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 25/2/25.
//

import SwiftUI
import ZafirUI

/// A view that selects the camera's capture mode.
struct CaptureModeView<CameraModel: Camera>: View {
    @Bindable var camera: CameraModel

    var body: some View {
        SlidingSegmentedControl(
            selection: $camera.config.captureMode,
            values: CaptureMode.allCases
        ) { value in
            Label(value.description, systemImage: value.systemName)
                .labelStyle(.iconOnly)
                .accessibilityLabel(value.description)
        }
        .disabled(camera.captureActivity.isRecording)
        .disabled(!camera.config.isCaptureModeVisible)
        .opacity(camera.config.isCaptureModeVisible ? 1 : 0)
        .onChange(of: camera.swipeDirection) { _, newValue in
            guard !camera.captureActivity.isRecording, !camera.isSwitching else { return }

            if newValue.isHorizontal, camera.config.isCaptureModeVisible {
                camera.config.captureMode = camera.config.captureMode.toggle()
            } else {
                Task { await camera.switchVideoDevices() }
            }
        }
    }
}
