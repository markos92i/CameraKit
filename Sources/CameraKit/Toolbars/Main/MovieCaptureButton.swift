//
//  MovieCaptureButton.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 6/8/24.
//

import SwiftUI

struct MovieCaptureButton: View {
    private let action: (Bool) -> Void
    private let lineWidth = CGFloat(4.0)
    
    @Binding private var isRecording: Bool
    
    init(isRecording: Binding<Bool>, action: @escaping (Bool) -> Void) {
        _isRecording = isRecording
        self.action = action
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: lineWidth)
                .foregroundStyle(Color.white)
            Button {
                isRecording.toggle()
                action(isRecording)
            } label: {
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: geometry.size.width / (isRecording ? 4.0 : 2.0))
                        .inset(by: lineWidth * 1.2)
                        .fill(.red)
                        .scaleEffect(isRecording ? 0.6 : 1.0)
                }
            }
            .buttonStyle(NoFadeButtonStyle())
        }
        .animation(.easeInOut, value: isRecording)
    }
    
    struct NoFadeButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
        }
    }
}

#Preview {
    @Previewable @State var isRecording = false
    
    ZStack {
        Color.gray
            .ignoresSafeArea()
        
        MovieCaptureButton(isRecording: $isRecording) { _ in
            
        }
        .frame(width: 60, height: 60)
        .padding(100)
    }
}
