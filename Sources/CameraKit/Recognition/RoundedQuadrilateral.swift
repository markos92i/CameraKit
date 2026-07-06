import SwiftUI

struct RoundedQuadrilateral: Shape {
    var points: [CGPoint]
    var radius: CGFloat
    
    var animatableData: AnimatableQuad {
        get { .init(points: points) }
        set { points = newValue.points }
    }

    // Ensure exactly 4 points are provided
    init(points: [CGPoint], radius: CGFloat) {
        self.points = points
        self.radius = radius
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard points.count == 4 else { return path }
        
        for i in 0..<points.count {
            let currentPoint = points[i]
            let previousPoint = points[(i - 1 + points.count) % points.count]
            let nextPoint = points[(i + 1) % points.count]
            
            // Calculate direction vectors to previous and next points
            let toPrevious = (previousPoint - currentPoint).normalized()
            let toNext = (nextPoint - currentPoint).normalized()
            
            // Calculate offset points (radius distance from the corner)
            let startOffset = currentPoint + toPrevious * radius
            let endOffset = currentPoint + toNext * radius
            
            if i == 0 {
                path.move(to: startOffset)
            } else {
                path.addLine(to: startOffset)
            }
            
            // Add a quadratic curve to round the corner
            path.addQuadCurve(to: endOffset, control: currentPoint)
        }
        
        path.closeSubpath()
        return path
    }
    
    struct AnimatableQuad: VectorArithmetic {
        var points: [CGPoint]

        var magnitudeSquared: Double {  points.reduce(0) { $0 + $1.x * $1.x + $1.y * $1.y } }

        static var zero: Self { .init(points: .init(repeating: .zero, count: 4)) }

        static func +(lhs: Self, rhs: Self) -> Self {
            .init(points: zip(lhs.points, rhs.points).map(+))
        }
        
        static func -(lhs: Self, rhs: Self) -> Self {
            .init(points: zip(lhs.points, rhs.points).map(-))
        }

        mutating func scale(by rhs: Double) {
            points = points.map { $0 * CGFloat(rhs) }
        }
    }
}

// MARK: - CGPoint Extensions
extension CGPoint {
    static func +(lhs: Self, rhs: Self) -> Self {
        .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func -(lhs: Self, rhs: Self) -> Self {
        .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    static func *(lhs: Self, rhs: CGFloat) -> Self {
        .init(x: lhs.x * rhs, y: lhs.y * rhs)
    }
    
    static func *(lhs: Self, rhs: CGRect) -> Self {
        .init(x: lhs.x * rhs.width, y: lhs.y * rhs.height)
    }

    func normalized() -> CGPoint {
        let length = sqrt(x * x + y * y)
        return length > 0 ? CGPoint(x: x / length, y: y / length) : .zero
    }
}
