//
//  FocusOverlayView.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 17/2/25.
//

import Foundation
import SwiftUI
import AVFoundation

struct FocusOverlayView: View {

    @State private var isPressing = false
    @State private var longPressPoint: CGPoint = .zero

    private let camera: Camera

    enum PreviewType {
        case tap
        case longPress
    }

    init(camera: Camera) {
        self.camera = camera
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(camera.focusPoints) { indicator in
                    focusSquare(for: indicator, geometry: geometry)
                }
                Rectangle()
                    .fill(.clear)
                    .contentShape(.rect)
                    .onTapGesture { point in
                        preview(at: point.normalized(for: geometry), type: .tap)
                    }
                    .onLongPressGesture(minimumDuration: 0.3) {
                        preview(at: longPressPoint.normalized(for: geometry), type: .longPress)
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard !isPressing else { return }
                                isPressing = true
                                longPressPoint = value.location
                            }
                            .onEnded { _ in
                                isPressing = false
                            }
                    )
            }
        }
    }

    private func preview(at point: CGPoint, type: PreviewType) {
        Task {
            switch type {
            case .tap:
                await camera.focusAndExpose(at: point)
            case .longPress:
                // await camera.longPressPreview(at: point)
                break
            }
        }
    }

    private func focusSquare(for indicator: FocusIndicator, geometry: GeometryProxy) -> some View {
        let size = geometry.size.width * 0.18
        let x = indicator.position.x * geometry.size.width
        let y = indicator.position.y * geometry.size.height

        return FocusSquare(size: size)
            .id(indicator.id)
            .position(x: x, y: y)
    }
}

private struct FocusSquare: View {
    let size: CGFloat
    @State private var scale: CGFloat = 1.5
    @State private var opacity: Double = 1

    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(.yellow, lineWidth: 1.5)
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                scale = 1.5
                opacity = 1
                withAnimation(.spring(duration: 0.15)) {
                    scale = 1.0
                }
                withAnimation(.easeOut(duration: 0.2).delay(0.8)) {
                    opacity = 0
                }
            }
    }
}

fileprivate extension CGPoint {
    func normalized(for proxy: GeometryProxy) -> CGPoint {
        .init(x: x / proxy.size.width, y: y / proxy.size.height)
    }
}
