//
//  HDRButton.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 25/2/25.
//

import SwiftUI

struct HDRButton<CameraModel: Camera>: View {
    @State var camera: CameraModel
    
    var body: some View {
        Button {
            camera.isHDRVideoEnabled.toggle()
        } label: {
            Label("HDR", systemImage: camera.isHDRVideoEnabled ? "sparkles.rectangle.stack.fill" : "sparkles.rectangle.stack")
        }
        .buttonStyle(CameraButtonStyle(size: .small))
        .disabled(camera.captureActivity.isRecording)
    }
}
