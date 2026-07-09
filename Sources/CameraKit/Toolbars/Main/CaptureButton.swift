//
//  CaptureButton.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 16/6/25.
//


import SwiftUI

/// A view that displays an appropriate capture button for the selected mode.
@MainActor
struct CaptureButton<CameraModel: Camera>: View {
    
    @State var camera: CameraModel
    @State var isRecording = false
    
    private let mainButtonDimension: CGFloat = 68
    
    var body: some View {
        captureButton
            .aspectRatio(1.0, contentMode: .fit)
            .frame(width: 60, height: 60)
            // Respond to recording state changes that occur from hardware button presses.
            .onChange(of: camera.captureActivity.isRecording) { _, newValue in
                // Ensure the button animation occurs when toggling recording state from a hardware button.
                withAnimation(.easeInOut(duration: 0.25)) {
                    isRecording = newValue
                }
            }
    }
    
    @ViewBuilder
    var captureButton: some View {
        switch camera.config.captureMode {
        case .photo:
            PhotoCaptureButton {
                Task { await camera.capturePhoto() }
            }
        case .video:
            MovieCaptureButton(isRecording: $isRecording) { _ in
                Task { await camera.toggleRecording() }
            }
        }
    }
}

#Preview("Photo") {
    CaptureButton(camera: PreviewCameraModel(captureMode: .photo))
}

#Preview("Video") {
    CaptureButton(camera: PreviewCameraModel(captureMode: .video))
}

