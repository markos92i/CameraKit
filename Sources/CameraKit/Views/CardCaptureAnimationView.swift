//
//  CardCaptureAnimationView.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 6/7/25.
//

import SwiftUI

/// Animates the captured card from its detected perspective position to the final flat preview.
struct CardCaptureAnimationView: View {
    let photo: UIImage
    @Binding var phase: CapturePhase
    let quadrilateral: CaptureMetadata?
    let containerSize: CGSize

    @State private var progress: CGFloat = 0

    private var width: CGFloat { containerSize.width * 0.8 }
    private var height: CGFloat { width * (photo.size.height / photo.size.width) }
    private var radius: CGFloat { (width / 85.6) * 3.03 }

    var body: some View {
        Image(uiImage: photo)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height)
            .clipShape(.rect(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(.white.opacity(0.7), lineWidth: 2)
            )
            .modifier(
                PerspectiveLiftEffect(
                    progress: progress,
                    initialTransform: initialTransform
                )
            )
            .onAppear {
                phase = .animating
                withAnimation(.spring(duration: 0.6, bounce: 0.15)) {
                    progress = 1
                } completion: {
                    phase = .ready
                }
            }
    }

    /// Pre-computed initial transform (perspective from detected quad).
    private var initialTransform: CATransform3D {
        guard let quad = quadrilateral else { return CATransform3DIdentity }
        let points = CGPointUtils.convertToAspectFill(
            quad.flippedPoints,
            source: quad.image.extent.size,
            target: containerSize
        )
        guard points.count == 4 else { return CATransform3DIdentity }

        let destOrigin = CGPoint(
            x: (containerSize.width - width) / 2,
            y: (containerSize.height - height) / 2
        )

        let localQuad = points.map { CGPoint(x: $0.x - destOrigin.x, y: $0.y - destOrigin.y) }
        let viewRect: [CGPoint] = [
            .zero,
            CGPoint(x: width, y: 0),
            CGPoint(x: width, y: height),
            CGPoint(x: 0, y: height)
        ]

        return HomographySolver.solve(from: viewRect, to: localQuad)
    }
}

// MARK: - Perspective Lift Effect

/// Interpolates a CATransform3D from an initial perspective transform to identity.
struct PerspectiveLiftEffect: GeometryEffect {
    var progress: CGFloat
    let initialTransform: CATransform3D

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        let t = progress
        var result = CATransform3DIdentity
        result.m11 = lerp(initialTransform.m11, 1.0, t)
        result.m12 = lerp(initialTransform.m12, 0.0, t)
        result.m14 = lerp(initialTransform.m14, 0.0, t)
        result.m21 = lerp(initialTransform.m21, 0.0, t)
        result.m22 = lerp(initialTransform.m22, 1.0, t)
        result.m24 = lerp(initialTransform.m24, 0.0, t)
        result.m41 = lerp(initialTransform.m41, 0.0, t)
        result.m42 = lerp(initialTransform.m42, 0.0, t)
        result.m44 = lerp(initialTransform.m44, 1.0, t)
        return ProjectionTransform(result)
    }

    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }
}

// MARK: - Homography Solver

/// Solves a 2D homography (8-parameter perspective transform) between two quadrilaterals.
enum HomographySolver {
    static func solve(from src: [CGPoint], to dst: [CGPoint]) -> CATransform3D {
        guard src.count == 4, dst.count == 4 else { return CATransform3DIdentity }

        var A = [[Double]](repeating: [Double](repeating: 0, count: 8), count: 8)
        var b = [Double](repeating: 0, count: 8)

        for i in 0..<4 {
            let x = Double(src[i].x), y = Double(src[i].y)
            let u = Double(dst[i].x), v = Double(dst[i].y)
            A[i * 2]     = [x, y, 1, 0, 0, 0, -u * x, -u * y]
            b[i * 2]     = u
            A[i * 2 + 1] = [0, 0, 0, x, y, 1, -v * x, -v * y]
            b[i * 2 + 1] = v
        }

        let h = gaussianElimination(A, b)
        guard h.count == 8 else { return CATransform3DIdentity }

        // Map to CATransform3D for ProjectionTransform:
        // [x' y' w'] = [x y 1] * [[m11 m12 m14], [m21 m22 m24], [m41 m42 m44]]
        var t = CATransform3DIdentity
        t.m11 = CGFloat(h[0])
        t.m12 = CGFloat(h[3])
        t.m14 = CGFloat(h[6])
        t.m21 = CGFloat(h[1])
        t.m22 = CGFloat(h[4])
        t.m24 = CGFloat(h[7])
        t.m41 = CGFloat(h[2])
        t.m42 = CGFloat(h[5])
        t.m44 = 1.0
        return t
    }

    private static func gaussianElimination(_ matrix: [[Double]], _ rhs: [Double]) -> [Double] {
        let n = rhs.count
        var A = matrix
        var b = rhs

        for col in 0..<n {
            var maxRow = col
            var maxVal = abs(A[col][col])
            for row in (col + 1)..<n where abs(A[row][col]) > maxVal {
                maxVal = abs(A[row][col])
                maxRow = row
            }
            if maxRow != col {
                A.swapAt(col, maxRow)
                b.swapAt(col, maxRow)
            }
            guard abs(A[col][col]) > 1e-10 else { return [] }

            for row in (col + 1)..<n {
                let factor = A[row][col] / A[col][col]
                for k in col..<n { A[row][k] -= factor * A[col][k] }
                b[row] -= factor * b[col]
            }
        }

        var x = [Double](repeating: 0, count: n)
        for i in stride(from: n - 1, through: 0, by: -1) {
            var sum = b[i]
            for j in (i + 1)..<n { sum -= A[i][j] * x[j] }
            x[i] = sum / A[i][i]
        }
        return x
    }
}
