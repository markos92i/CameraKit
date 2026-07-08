//
//  QualityPicker.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 25/2/25.
//

import SwiftUI

struct QualityPicker<CameraModel: Camera>: View {
    @Bindable var camera: CameraModel
    
    var body: some View {
        Menu {
            Picker("calidad", selection: $camera.qualityPrioritization) {
                ForEach(QualityPrioritization.allCases) {
                    Text($0.description)
                }
            }
        } label: {
            Label("cambiar calidad", systemImage: camera.qualityPrioritization.systemName)
                .labelStyle(CameraButtonLabel(size: .small, icon: true, text: false))
        }
    }
}
