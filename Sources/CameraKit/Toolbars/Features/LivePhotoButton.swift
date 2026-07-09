//
//  LivePhotoButton.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 25/2/25.
//

import SwiftUI

struct LivePhotoButton<CameraModel: Camera>: View {
    @State var camera: CameraModel
    
    var body: some View {
        Button {
            camera.config.isLivePhotoEnabled.toggle()
        } label: {
            Label("live photo", systemImage: camera.config.isLivePhotoEnabled ? "livephoto" : "livephoto.slash")
        }
        .buttonStyle(CameraButtonStyle(size: .small))
    }
}
