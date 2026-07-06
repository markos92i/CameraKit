//
//  PhotoCaptureButton.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 6/8/24.
//

import SwiftUI

struct PhotoCaptureButton: View {
    private let action: () -> Void
    private let lineWidth: CGFloat = 4.0
    
    init(action: @escaping () -> Void) {
        self.action = action
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .fill(.white)
            Button {
                action()
            } label: {
                Circle()
                    .inset(by: lineWidth * 1.2)
                    .fill(.white)
            }
            .buttonStyle(PhotoButtonStyle())
        }
    }
    
    struct PhotoButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
        }
    }
}

#Preview {
    ZStack {
        Color.gray
            .ignoresSafeArea()
        
        PhotoCaptureButton() {
            
        }
        .frame(width: 60, height: 60)
        .padding(100)
    }
}
