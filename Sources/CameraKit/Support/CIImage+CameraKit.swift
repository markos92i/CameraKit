import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

extension CIImage {
    public var uiImage: UIImage? {
        guard let metalDevice = MTLCreateSystemDefaultDevice() else { return nil }
        guard let cgImage = CIContext(mtlDevice: metalDevice).createCGImage(self, from: extent) else { return nil }
        return UIImage(cgImage: cgImage)
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
}
