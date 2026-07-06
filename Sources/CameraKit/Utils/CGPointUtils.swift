import CoreGraphics

struct CGPointUtils {
    /// Projects points of a [0-1] size over a new given size
    static func scale(_ points: [CGPoint], to size: CGSize) -> [CGPoint] {
        points.map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }
    }
    
    static func center(of points: [CGPoint]) -> CGPoint {
        let sum = points.reduce((0, 0)) { ($0.0 + $1.x, $0.1 + $1.y) }
        return CGPoint(x: sum.0/CGFloat(points.count), y: sum.1/CGFloat(points.count))
    }

    /// Calculate the bounding box (CGRect) of an array of points.
    static func boundingRect(for points: [CGPoint]) -> CGRect {
        guard !points.isEmpty else { return .zero }
        
        var minX = CGFloat.infinity
        var minY = CGFloat.infinity
        var maxX = -CGFloat.infinity
        var maxY = -CGFloat.infinity
        
        points.forEach { point in
            minX = min(minX, point.x)
            minY = min(minY, point.y)
            maxX = max(maxX, point.x)
            maxY = max(maxY, point.y)
        }
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    static func identity(for points: [CGPoint]) -> [CGPoint] {
        let extent = boundingRect(for: points)
        return [
            CGPoint(x: extent.minX, y: extent.minY),
            CGPoint(x: extent.maxX, y: extent.minY),
            CGPoint(x: extent.maxX, y: extent.maxY),
            CGPoint(x: extent.minX, y: extent.maxY)
        ]
    }

    /// Flip points horizontally around the center of their bounding box.
    static func flipHorizontally(_ points: [CGPoint], extent: CGRect) -> [CGPoint] {
        points.map { CGPoint(x: 2 * extent.midX - $0.x, y: $0.y) }
    }

    /// Flip points vertically around the center of their bounding box.
    static func flipVertically(_ points: [CGPoint], extent: CGRect) -> [CGPoint] {
        points.map { CGPoint(x: $0.x, y: 2 * extent.midY - $0.y) }
    }
    
    /// Rotate points around the center of their bounding box by a given angle (radians).
    static func rotate(_ points: [CGPoint], extent: CGRect, angle: CGFloat) -> [CGPoint] {
        let center = CGPoint(x: extent.midX, y: extent.midY)
        let cosAngle = cos(angle)
        let sinAngle = sin(angle)
        
        return points.map { point in
            let translatedX = point.x - center.x
            let translatedY = point.y - center.y
            
            let rotatedX = translatedX * cosAngle - translatedY * sinAngle
            let rotatedY = translatedX * sinAngle + translatedY * cosAngle
            
            return CGPoint(x: rotatedX + center.x, y: rotatedY + center.y)
        }
    }
    
    /// Translates points that match over an image to match over its containing view if we apply aspectFill to it.
    static func convertToAspectFill(_ points: [CGPoint], source: CGSize, target: CGSize) -> [CGPoint] {
        guard source.width > 0, source.height > 0 else { return [] }
        
        let scale = max(target.width / source.width, target.height / source.height)
        let scaledSize = CGSize(width: source.width * scale, height: source.height * scale)
        
        let offsetX = (scaledSize.width - target.width) / 2
        let offsetY = (scaledSize.height - target.height) / 2
        
        return points.map { CGPoint(x: $0.x * scale - offsetX, y: $0.y * scale - offsetY) }
    }
}
