//
//  CaptureOverlayView.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 16/6/25.
//

import SwiftUI
import AVKit

// MARK: - Capture Phase

/// The animation phase for capture overlays.
/// Each filter mode uses these phases to orchestrate its transition.
enum CapturePhase: Equatable {
    /// Content just appeared, initial layout (perspective position for cards, overlay position for text).
    case initial
    /// Animating from initial to final resting position.
    case animating
    /// Final interactive state (card flat + confirm, text list editable + confirm).
    case ready
}

// MARK: - Capture Overlay View

struct CaptureOverlayView: View {
    private let camera: Camera
    @State private var phase: CapturePhase = .initial

    init(camera: Camera) {
        self.camera = camera
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear

                switch camera.captureSnapshot {
                case .photo(let photo, _, let metadata):
                    switch camera.config.imageFilter {
                    case .cards:
                        CardCaptureAnimationView(
                            photo: photo,
                            phase: $phase,
                            quadrilateral: metadata.first,
                            containerSize: geometry.size
                        )
                    case .text:
                        TextCaptureAnimationView(
                            photo: photo,
                            phase: $phase,
                            features: metadata,
                            containerSize: geometry.size
                        )
                    case .none:
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    }
                case .video(let url):
                    VideoPlayer(player: AVPlayer(url: url))
                case nil:
                    EmptyView()
                }
            }
        }
        .onChange(of: camera.captureSnapshot != nil) { _, hasCaptured in
            phase = .initial
        }
    }
}
