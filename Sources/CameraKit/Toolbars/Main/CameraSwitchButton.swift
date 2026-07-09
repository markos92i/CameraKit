//
//  CameraSwitchButton.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 25/2/25.
//

import SwiftUI

/// A view that toggles the camera's capture mode.
struct CameraSwitchButton<CameraModel: Camera>: View {
    @State var camera: CameraModel
        
    var body: some View {
        Button {
            Task { await camera.switchVideoDevices() }
        } label: {
            Label("cambiar cámara", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
        }
        .buttonStyle(CameraButtonStyle(size: .medium))
        .disabled(camera.captureActivity.isRecording)
        .opacity(camera.captureActivity.isRecording ? 0 : 1)
        .allowsHitTesting(!camera.isSwitching)
    }
}
