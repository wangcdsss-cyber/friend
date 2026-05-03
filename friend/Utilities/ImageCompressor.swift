import UIKit

struct ImageCompressor {
    static func jpegData(from image: UIImage, maxDimension: CGFloat = 1600, quality: CGFloat = 0.75) -> Data? {
        let resized = resize(image: image, maxDimension: maxDimension)
        return resized.jpegData(compressionQuality: quality)
    }

    static func resize(image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension, maxSide > 0 else { return image }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

