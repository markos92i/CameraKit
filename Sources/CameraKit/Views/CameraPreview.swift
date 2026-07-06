//
//  PreviewMetalView.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 22/2/25.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    private let preview: AVSampleBufferDisplayLayer
    private let videoGravity: AVLayerVideoGravity

    init(preview: AVSampleBufferDisplayLayer, videoGravity: AVLayerVideoGravity) {
        self.preview = preview
        self.videoGravity = videoGravity
    }

    func makeUIView(context: Context) -> PreviewView {
        PreviewView(preview: preview, videoGravity: videoGravity)
    }

    func updateUIView(_ previewView: PreviewView, context: Context) {
        // No implementation needed.
    }

    class PreviewView: UIView {
        let preview: AVSampleBufferDisplayLayer
        let videoGravity: AVLayerVideoGravity

        init(preview: AVSampleBufferDisplayLayer, videoGravity: AVLayerVideoGravity) {
            self.preview = preview
            self.videoGravity = videoGravity
            super.init(frame: .zero)
            layer.addSublayer(preview)
            #if targetEnvironment(simulator)
            backgroundColor = .black
            let imageView = UIImageView()
            imageView.image = UIImage(systemName: "camera.viewfinder")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 60))
            imageView.tintColor = .white.withAlphaComponent(0.3)
            imageView.contentMode = .center
            imageView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
            #endif
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            preview.frame = bounds
            preview.videoGravity = videoGravity
        }
    }
}
