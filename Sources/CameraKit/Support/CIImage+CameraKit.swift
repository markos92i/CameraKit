import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

extension CIImage {
    func oriented(for orientation: UIDeviceOrientation) -> CIImage {
        switch orientation {
        case .portrait:         return oriented(.up)
        case .landscapeRight:   return oriented(.left)
        case .landscapeLeft:    return oriented(.right)
        case .portraitUpsideDown: return oriented(.up)
        default:                return self
        }
    }

    func scaled(_ scale: Float) -> CIImage {
        let filter = CIFilter.lanczosScaleTransform()
        filter.inputImage = self
        filter.scale = scale
        return filter.outputImage!
    }

    func resized(_ size: CGFloat) -> CIImage {
        let scale = size / extent.width
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        return transformed(by: transform)
    }

    var cgImg: CGImage? { CIContext().createCGImage(self, from: extent) }

    public var uiImage: UIImage? {
        guard let metalDevice = MTLCreateSystemDefaultDevice() else { return nil }
        guard let cgImage = CIContext(mtlDevice: metalDevice).createCGImage(self, from: extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    var swiftUIImage: Image? {
        guard let cgImg else { return nil }
        return Image(decorative: cgImg, scale: 1, orientation: .up)
    }

    func perspective(points: [CGPoint]) -> CIImage {
        guard points.count == 4 else { return self }
        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = self
        filter.topLeft = points[0]
        filter.topRight = points[1]
        filter.bottomRight = points[2]
        filter.bottomLeft = points[3]
        return filter.outputImage!
    }

    func highlight(points: [CGPoint]) -> CIImage {
        guard points.count == 4 else { return self }
        var overlay = CIImage(color: CIColor(red: 0, green: 0, blue: 1, alpha: 0.3))
        overlay = overlay.cropped(to: extent)
        let filter = CIFilter.perspectiveTransformWithExtent()
        filter.inputImage = overlay
        filter.extent = extent
        filter.topLeft = points[0]
        filter.topRight = points[1]
        filter.bottomRight = points[2]
        filter.bottomLeft = points[3]
        guard let transformedOverlay = filter.outputImage else { return self }
        return transformedOverlay.composited(over: self)
    }
}
