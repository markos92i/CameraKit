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
    /// Snapshot of detected features at the moment of capture (survives featureMetadata clearing).
    @State private var capturedFeatures: [FeatureMetadata] = []

    init(camera: Camera) {
        self.camera = camera
    }

    /// Returns the best available features: snapshot if available, otherwise live data.
    private var activeFeatures: [FeatureMetadata] {
        capturedFeatures.isEmpty ? camera.featureMetadata : capturedFeatures
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear

                if let photo = camera.lastPhoto {
                    switch camera.imageFilter {
                    case .cards:
                        CardCaptureAnimationView(
                            photo: photo,
                            phase: $phase,
                            quadrilateral: activeFeatures.first,
                            containerSize: geometry.size
                        )
                    case .text:
                        TextCaptureAnimationView(
                            photo: photo,
                            phase: $phase,
                            editableTexts: Binding(
                                get: { camera.editableTexts },
                                set: { camera.editableTexts = $0 }
                            ),
                            features: activeFeatures,
                            containerSize: geometry.size
                        )
                    case .none:
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    }
                } else if let video = camera.lastVideo {
                    VideoPlayer(player: AVPlayer(url: video))
                }
            }
        }
        .onChange(of: camera.lastPhoto != nil) { _, hasCaptured in
            if hasCaptured {
                capturedFeatures = camera.featureMetadata
                phase = .initial
            } else {
                capturedFeatures = []
                phase = .initial
            }
        }
    }
}
