//
//  FilterPicker.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 25/2/25.
//

import SwiftUI

struct FilterPicker<CameraModel: Camera>: View {
    @State var camera: CameraModel
    
    var body: some View {
        Menu {
            Picker("filtros", selection: $camera.imageFilter) {
                ForEach(ImageFilter.allCases) {
                    Text($0.description)
                }
            }
        } label: {
            Label("cambiar filtros", systemImage: camera.imageFilter.systemName)
                .labelStyle(CameraButtonLabel(size: .small, icon: true, text: false))
        }
    }
}
