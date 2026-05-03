import XCTest
import UIKit
@testable import friend

final class ImageCompressorTests: XCTestCase {
    func testResizeReducesLargeImage() {
        let size = CGSize(width: 4000, height: 3000)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }

        let resized = ImageCompressor.resize(image: image, maxDimension: 1600)
        XCTAssertLessThanOrEqual(max(resized.size.width, resized.size.height), 1600)
    }

    func testJpegDataNotNil() {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }

        let data = ImageCompressor.jpegData(from: image, maxDimension: 1600, quality: 0.75)
        XCTAssertNotNil(data)
        XCTAssertGreaterThan(data?.count ?? 0, 0)
    }
}

