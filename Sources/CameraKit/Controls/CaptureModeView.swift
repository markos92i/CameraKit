//
//  CaptureModeView.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 25/2/25.
//

import SwiftUI

/// A view that toggles the camera's capture mode.
struct CaptureModeView<CameraModel: Camera>: View {
    @State var camera: CameraModel
        
    var body: some View {
        HStack(spacing: 0) {
            ForEach(CaptureMode.allCases) { value in
                Button {
                    camera.config.captureMode = value
                } label: {
                    Label(value.description, systemImage: value.systemName)
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Capsule().fill(.black.opacity(camera.config.captureMode == value ? 0.4 : 0)))
                        .padding(4)
                }
            }
        }
        .background(Capsule().fill(.black.opacity(0.3)))
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
