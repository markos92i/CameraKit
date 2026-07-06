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
    let width: CGFloat
    let height: CGFloat
    let radius: CGFloat
    let quadrilateral: FeatureMetadata?
    let containerSize: CGSize

    @State private var progress: CGFloat = 0

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
                    sourceQuad: sourcePoints,
                    destinationSize: CGSize(width: width, height: height),
                    containerSize: containerSize
                )
            )
            .onAppear {
                withAnimation(.spring(duration: 0.6, bounce: 0.15)) {
                    progress = 1
                }
            }
    }

    /// The detected quadrilateral points converted to container coordinates.
    private var sourcePoints: [CGPoint] {
        guard let quad = quadrilateral else { return [] }
        let points = CGPointUtils.convertToAspectFill(
            quad.flippedPoints,
            source: quad.image.extent.size,
            target: containerSize
        )
        guard points.count == 4 else { return [] }
        return points
    }
}

/// Animates a view from a perspective quadrilateral to its flat resting position using CATransform3D.
struct PerspectiveLiftEffect: GeometryEffect {
    var progress: CGFloat

    let sourceQuad: [CGPoint]
    let destinationSize: CGSize
    let containerSize: CGSize

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        guard sourceQuad.count == 4 else { return ProjectionTransform(.identity) }

        // The view is centered in the container. Compute where its corners are in container space.
        let destOrigin = CGPoint(
            x: (containerSize.width - size.width) / 2,
            y: (containerSize.height - size.height) / 2
        )

        // Destination corners in container-space
        let dst = [
            CGPoint(x: destOrigin.x, y: destOrigin.y),
            CGPoint(x: destOrigin.x + size.width, y: destOrigin.y),
            CGPoint(x: destOrigin.x + size.width, y: destOrigin.y + size.height),
            CGPoint(x: destOrigin.x, y: destOrigin.y + size.height)
        ]

        // Interpolate each corner between source (detected) and destination (flat)
        let interpolated = zip(sourceQuad, dst).map { (src, end) in
            CGPoint(
                x: src.x + (end.x - src.x) * progress,
                y: src.y + (end.y - src.y) * progress
            )
        }

        // Convert to view-local coordinates (relative to view origin)
        let localQuad = interpolated.map { CGPoint(x: $0.x - destOrigin.x, y: $0.y - destOrigin.y) }

        // Compute the homography that maps the view's unit rect to the interpolated quad
        let transform = homography(
            from: [.zero, CGPoint(x: size.width, y: 0), CGPoint(x: size.width, y: size.height), CGPoint(x: 0, y: size.height)],
            to: localQuad
        )

        return ProjectionTransform(transform)
    }

    /// Computes a full projective CATransform3D (homography) mapping 4 source points to 4 destination points.
    private func homography(from src: [CGPoint], to dst: [CGPoint]) -> CATransform3D {
        // Solve the 8-parameter homography H such that dst = H * src (in homogeneous coordinates).
        // H = [[h0, h1, h2], [h3, h4, h5], [h6, h7, 1]]
        //
        // For each point correspondence (x,y) -> (u,v):
        //   u = (h0*x + h1*y + h2) / (h6*x + h7*y + 1)
        //   v = (h3*x + h4*y + h5) / (h6*x + h7*y + 1)

        let n = 4
        // Build the 8x8 linear system
        var A = [[Double]](repeating: [Double](repeating: 0, count: 8), count: 8)
        var b = [Double](repeating: 0, count: 8)

        for i in 0..<n {
            let x = Double(src[i].x), y = Double(src[i].y)
            let u = Double(dst[i].x), v = Double(dst[i].y)
            let row1 = i * 2
            let row2 = i * 2 + 1
            A[row1] = [x, y, 1, 0, 0, 0, -u * x, -u * y]
            b[row1] = u
            A[row2] = [0, 0, 0, x, y, 1, -v * x, -v * y]
            b[row2] = v
        }

        // Solve using Gaussian elimination
        let h = solveLinearSystem(A, b)
        guard h.count == 8 else { return CATransform3DIdentity }

        // Map to CATransform3D (column-major, maps (x, y, 0, 1) → (x', y', 0, w'))
        // CATransform3D layout:
        //   m11 m12 m13 m14      col1
        //   m21 m22 m23 m24      col2
        //   m31 m32 m33 m34      col3
        //   m41 m42 m43 m44      col4
        //
        // For 2D homography applied via ProjectionTransform:
        //   [x' y' w'] = [x y 1] * [[m11 m12 m14], [m21 m22 m24], [m41 m42 m44]]
        //
        // So the mapping is:
        //   m11=h0, m12=h3, m14=h6
        //   m21=h1, m22=h4, m24=h7
        //   m41=h2, m42=h5, m44=1

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

    /// Solves Ax = b via Gaussian elimination with partial pivoting.
    private func solveLinearSystem(_ matrix: [[Double]], _ rhs: [Double]) -> [Double] {
        let n = rhs.count
        var A = matrix
        var b = rhs

        for col in 0..<n {
            // Partial pivoting
            var maxRow = col
            var maxVal = abs(A[col][col])
            for row in (col + 1)..<n {
                if abs(A[row][col]) > maxVal {
                    maxVal = abs(A[row][col])
                    maxRow = row
                }
            }
            if maxRow != col {
                A.swapAt(col, maxRow)
                b.swapAt(col, maxRow)
            }

            guard abs(A[col][col]) > 1e-10 else { return [] }

            // Eliminate below
            for row in (col + 1)..<n {
                let factor = A[row][col] / A[col][col]
                for k in col..<n {
                    A[row][k] -= factor * A[col][k]
                }
                b[row] -= factor * b[col]
            }
        }

        // Back substitution
        var x = [Double](repeating: 0, count: n)
        for i in stride(from: n - 1, through: 0, by: -1) {
            var sum = b[i]
            for j in (i + 1)..<n {
                sum -= A[i][j] * x[j]
            }
            x[i] = sum / A[i][i]
        }

        return x
    }
}
