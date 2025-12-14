//
//  ImageTransformerTests.swift
//  ImageManagerTests
//
//  Created by NVR4GET
//

import XCTest
@testable import ImageManager

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

final class ImageTransformerTests: XCTestCase {
    
    var transformer: ImageTransformer!
    
    override func setUp() {
        transformer = ImageTransformer()
    }
    
    override func tearDown() {
        transformer = nil
    }
    
    // MARK: - Helper Methods
    
    func createTestImageData(width: CGFloat, height: CGFloat) -> Data {
        #if canImport(UIKit)
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.jpegData(compressionQuality: 1.0)!
        #elseif canImport(AppKit)
        let size = NSSize(width: width, height: height)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.blue.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            fatalError("Failed to create test image")
        }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 1.0])!
        #endif
    }
    
    func getImageSize(from data: Data) -> CGSize? {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else { return nil }
        return image.size
        #elseif canImport(AppKit)
        guard let image = NSImage(data: data) else { return nil }
        return image.size
        #endif
    }
    
    // MARK: - Crop Tests
    
    func testCropToSquare() async throws {
        // Create 16:9 landscape image
        let data = createTestImageData(width: 1600, height: 900)
        
        // Crop to 1:1 (square)
        let config = ImageTransformConfig(cropRatio: 1.0, compressionQuality: 1.0)
        let transformed = try await transformer.transform(data, config: config)
        
        let size = getImageSize(from: transformed)
        XCTAssertNotNil(size)
        
        // Should be square
        if let size = size {
            XCTAssertEqual(size.width, size.height, accuracy: 1.0)
            // Should crop width (landscape -> square)
            XCTAssertEqual(size.width, 900, accuracy: 1.0)
        }
    }
    
    func testCropTo16by9() async throws {
        // Create square image
        let data = createTestImageData(width: 1000, height: 1000)
        
        // Crop to 16:9
        let config = ImageTransformConfig(cropRatio: 16/9, compressionQuality: 1.0)
        let transformed = try await transformer.transform(data, config: config)
        
        let size = getImageSize(from: transformed)
        XCTAssertNotNil(size)
        
        if let size = size {
            let aspectRatio = size.width / size.height
            XCTAssertEqual(aspectRatio, 16/9, accuracy: 0.01)
            // Should crop height (square -> widescreen)
            XCTAssertEqual(size.width, 1000, accuracy: 1.0)
        }
    }
    
    func testNoCropWhenAlreadyCorrectRatio() async throws {
        // Create 16:9 image
        let data = createTestImageData(width: 1600, height: 900)
        
        // Crop to 16:9 (should not change)
        let config = ImageTransformConfig(cropRatio: 16/9, compressionQuality: 1.0)
        let transformed = try await transformer.transform(data, config: config)
        
        let size = getImageSize(from: transformed)
        XCTAssertNotNil(size)
        
        if let size = size {
            XCTAssertEqual(size.width, 1600, accuracy: 1.0)
            XCTAssertEqual(size.height, 900, accuracy: 1.0)
        }
    }
    
    // MARK: - Resize Tests
    
    func testResizeToMaxDimension() async throws {
        // Create large image
        let data = createTestImageData(width: 2000, height: 1500)
        
        // Resize to max 1000px
        let config = ImageTransformConfig(compressionQuality: 1.0, maxDimension: 1000)
        let transformed = try await transformer.transform(data, config: config)
        
        let size = getImageSize(from: transformed)
        XCTAssertNotNil(size)
        
        if let size = size {
            // Max dimension should be 1000
            let maxDim = max(size.width, size.height)
            XCTAssertEqual(maxDim, 1000, accuracy: 1.0)
            
            // Aspect ratio should be preserved
            let originalRatio: CGFloat = 2000 / 1500
            let newRatio = size.width / size.height
            XCTAssertEqual(originalRatio, newRatio, accuracy: 0.01)
        }
    }
    
    func testNoResizeWhenSmallerThanMax() async throws {
        // Create small image
        let data = createTestImageData(width: 500, height: 400)
        
        // Set max to 1000px (larger than image)
        let config = ImageTransformConfig(compressionQuality: 1.0, maxDimension: 1000)
        let transformed = try await transformer.transform(data, config: config)
        
        let size = getImageSize(from: transformed)
        XCTAssertNotNil(size)
        
        if let size = size {
            // Should remain same size
            XCTAssertEqual(size.width, 500, accuracy: 1.0)
            XCTAssertEqual(size.height, 400, accuracy: 1.0)
        }
    }
    
    // MARK: - Compression Tests
    
    func testCompressionQuality() async throws {
        let data = createTestImageData(width: 1000, height: 1000)
        
        // High quality
        let highConfig = ImageTransformConfig(compressionQuality: 1.0)
        let highQuality = try await transformer.transform(data, config: highConfig)
        
        // Low quality
        let lowConfig = ImageTransformConfig(compressionQuality: 0.1)
        let lowQuality = try await transformer.transform(data, config: lowConfig)
        
        // Low quality should be smaller
        XCTAssertLessThan(lowQuality.count, highQuality.count)
    }
    
    // MARK: - Combined Transform Tests
    
    func testCombinedCropAndResize() async throws {
        // Create 2000x1500 image
        let data = createTestImageData(width: 2000, height: 1500)
        
        // Crop to 1:1 and resize to max 800px
        let config = ImageTransformConfig(
            cropRatio: 1.0,
            compressionQuality: 0.8,
            maxDimension: 800
        )
        let transformed = try await transformer.transform(data, config: config)
        
        let size = getImageSize(from: transformed)
        XCTAssertNotNil(size)
        
        if let size = size {
            // Should be square
            XCTAssertEqual(size.width, size.height, accuracy: 1.0)
            // Should be 800px
            XCTAssertEqual(size.width, 800, accuracy: 1.0)
        }
    }
    
    func testCombinedAllTransforms() async throws {
        // Create wide landscape image
        let data = createTestImageData(width: 3840, height: 2160)
        
        // Crop to 1:1, resize to 1024px, compress to 70%
        let config = ImageTransformConfig(
            cropRatio: 1.0,
            compressionQuality: 0.7,
            maxDimension: 1024
        )
        let transformed = try await transformer.transform(data, config: config)
        
        let size = getImageSize(from: transformed)
        XCTAssertNotNil(size)
        
        if let size = size {
            // Should be 1024x1024 square
            XCTAssertEqual(size.width, 1024, accuracy: 1.0)
            XCTAssertEqual(size.height, 1024, accuracy: 1.0)
        }
        
        // Should be significantly smaller than original
        XCTAssertLessThan(transformed.count, data.count)
    }
    
    // MARK: - Error Tests
    
    func testTransformInvalidData() async throws {
        let invalidData = Data("not an image".utf8)
        let config = ImageTransformConfig()
        
        do {
            _ = try await transformer.transform(invalidData, config: config)
            XCTFail("Expected error")
        } catch let error as ImageManagerError {
            if case .invalidImageData = error {
                // Expected
            } else {
                XCTFail("Expected invalidImageData error")
            }
        }
    }
    
    #if canImport(UIKit)
    // MARK: - UIImage Transform Tests
    
    func testTransformUIImage() async throws {
        let size = CGSize(width: 1000, height: 1000)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.green.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        
        let config = ImageTransformConfig(cropRatio: 16/9, compressionQuality: 0.8)
        let data = try await transformer.transform(image, config: config)
        
        XCTAssertGreaterThan(data.count, 0)
        
        // Verify it's a valid image
        let resultImage = UIImage(data: data)
        XCTAssertNotNil(resultImage)
    }
    #endif
    
    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    // MARK: - NSImage Transform Tests
    
    func testTransformNSImage() async throws {
        let size = NSSize(width: 1000, height: 1000)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.green.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        
        let config = ImageTransformConfig(cropRatio: 16/9, compressionQuality: 0.8)
        let data = try await transformer.transform(image, config: config)
        
        XCTAssertGreaterThan(data.count, 0)
        
        // Verify it's a valid image
        let resultImage = NSImage(data: data)
        XCTAssertNotNil(resultImage)
    }
    #endif
}
