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
            Picker(selection: $camera.config.qualityPrioritization) {
                ForEach(QualityPrioritization.allCases) {
                    Text($0.description)
                }
            } label: {
                Text("calidad", bundle: .module)
            }
        } label: {
            Label(String(localized: "cambiar calidad", bundle: .module), systemImage: camera.config.qualityPrioritization.systemName)
                .labelStyle(CameraButtonLabel(size: .small, icon: true, text: false))
        }
    }
}
