//
//  FeatureOverlayView.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 16/6/25.
//

import SwiftUI

struct FeatureOverlayView: View {
    private let camera: Camera

    init(camera: Camera) {
        self.camera = camera
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(camera.featureMetadata) { data in
                    let points = CGPointUtils.convertToAspectFill(data.flippedPoints, source: data.image.extent.size, target: geometry.size)

                    RoundedQuadrilateral(points: points, radius: data.radius)
                        .stroke(.blue, style: .init(lineWidth: data.lineWidth))
                        .fill(.blue.opacity(0.2))

                    if data.type == .text, !data.description.isEmpty {
                        let center = CGPointUtils.center(of: points)
                        let angle = atan2(points[1].y - points[0].y, points[1].x - points[0].x)
                        let width = hypot(points[1].x - points[0].x, points[1].y - points[0].y)

                        Text(data.description)
                            .font(.system(size: min(width * 0.15, 14)))
                            .foregroundStyle(.white)
                            .shadow(color: .black, radius: 2)
                            .rotationEffect(.radians(angle))
                            .position(x: center.x, y: center.y)
                    }
                }
            }
            .animation(.easeInOut, value: camera.featureMetadata)
        }
    }
}
