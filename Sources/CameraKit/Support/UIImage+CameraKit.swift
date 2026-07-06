import UIKit

extension UIImage {
    func store(quality: CGFloat = 1) -> URL? {
        guard let data = jpegData(compressionQuality: quality),
              let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy'_'HH'-'mm'-'ss"
        let url = dir.appendingPathComponent("\(formatter.string(from: .now)).jpg")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
