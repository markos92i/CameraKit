//
//  CaptureOverlayView.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 16/6/25.
//

import SwiftUI
import AVKit

struct CaptureOverlayView: View {
    private let camera: Camera

    init(camera: Camera) {
        self.camera = camera
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                
                if let photo = camera.lastPhoto {
                    switch camera.imageFilter {
                    case .cards:
                        cardPreview(photo: photo, geometry: geometry)
                    case .text:
                        textPreview(photo: photo, geometry: geometry)
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
    }

    private func cardPreview(photo: UIImage, geometry: GeometryProxy) -> some View {
        let ratio = photo.size.height / photo.size.width
        let width = geometry.size.width * 0.8
        let height = width * ratio
        let radius = (width / 85.6) * 3.03

        return CardCaptureAnimationView(
            photo: photo,
            width: width,
            height: height,
            radius: radius,
            quadrilateral: camera.featureMetadata.first,
            containerSize: geometry.size
        )
    }

    private func textPreview(photo: UIImage, geometry: GeometryProxy) -> some View {
        Image(uiImage: photo)
            .resizable()
            .scaledToFill()
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .overlay {
                // Keep showing the detected text regions over the captured image
                ForEach(camera.featureMetadata) { data in
                    if data.type == .text {
                        let points = CGPointUtils.convertToAspectFill(data.flippedPoints, source: data.image.extent.size, target: geometry.size)
                        let center = CGPointUtils.center(of: points)
                        let angle = atan2(points[1].y - points[0].y, points[1].x - points[0].x)
                        let width = hypot(points[1].x - points[0].x, points[1].y - points[0].y)

                        RoundedQuadrilateral(points: points, radius: data.radius)
                            .stroke(.blue, style: .init(lineWidth: data.lineWidth))
                            .fill(.blue.opacity(0.2))

                        Text(data.description)
                            .font(.system(size: min(width * 0.15, 14)))
                            .foregroundStyle(.white)
                            .shadow(color: .black, radius: 2)
                            .rotationEffect(.radians(angle))
                            .position(x: center.x, y: center.y)
                    }
                }
            }
    }
}

fileprivate extension CGPoint {
    func normalized(for proxy: GeometryProxy) -> CGPoint {
        .init(x: x / proxy.size.width, y: y / proxy.size.height)
    }
}
