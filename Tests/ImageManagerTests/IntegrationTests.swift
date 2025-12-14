//
//  IntegrationTests.swift
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

/// Integration tests combining ImageManager + ImageTransformer
final class IntegrationTests: XCTestCase {
    
    var manager: ImageManager!
    var transformer: ImageTransformer!
    var testDirectory: URL!
    
    override func setUp() async throws {
        let tempDir = FileManager.default.temporaryDirectory
        testDirectory = tempDir.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        
        let config = ImageManagerConfig(
            maxCacheSize: 10_000_000,
            maxCacheCount: 10,
            baseURL: testDirectory
        )
        manager = ImageManager(config: config)
        transformer = ImageTransformer()
    }
    
    override func tearDown() async throws {
        manager = nil
        transformer = nil
        try? FileManager.default.removeItem(at: testDirectory)
    }
    
    // MARK: - Helper
    
    func createTestImageData(width: CGFloat, height: CGFloat) -> Data {
        #if canImport(UIKit)
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.purple.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.jpegData(compressionQuality: 1.0)!
        #elseif canImport(AppKit)
        let size = NSSize(width: width, height: height)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.purple.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            fatalError("Failed to create test image")
        }
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 1.0])!
        #endif
    }
    
    // MARK: - Integration Tests
    
    func testTransformAndSaveWorkflow() async throws {
        // Create large landscape image
        let originalData = createTestImageData(width: 3840, height: 2160)
        
        // Transform: crop to 1:1, resize to 1024px, compress
        let config = ImageTransformConfig(
            cropRatio: 1.0,
            compressionQuality: 0.7,
            maxDimension: 1024
        )
        let transformedData = try await transformer.transform(originalData, config: config)
        
        // Save transformed image
        let filename = try await manager.save(transformedData)
        
        // Verify saved successfully
        let exists = await manager.exists(filename: filename)
        XCTAssertTrue(exists)
        
        // Load and verify dimensions
        #if canImport(UIKit)
        let result = await manager.loadUIImage(filename: filename)
        guard case .success(let image) = result else {
            XCTFail("Failed to load image")
            return
        }
        XCTAssertEqual(image.size.width, 1024, accuracy: 1.0)
        XCTAssertEqual(image.size.height, 1024, accuracy: 1.0)
        #elseif canImport(AppKit)
        let result = await manager.loadNSImage(filename: filename)
        guard case .success(let image) = result else {
            XCTFail("Failed to load image")
            return
        }
        XCTAssertEqual(image.size.width, 1024, accuracy: 1.0)
        XCTAssertEqual(image.size.height, 1024, accuracy: 1.0)
        #endif
        
        // Verify file size is smaller
        XCTAssertLessThan(transformedData.count, originalData.count)
    }
    
    func testMultipleSaveLoadCycle() async throws {
        var savedFilenames: [String] = []
        
        // Save multiple images
        for i in 0..<5 {
            let data = createTestImageData(width: CGFloat(100 + i * 50), height: 100)
            let config = ImageTransformConfig(compressionQuality: 0.8)
            let transformed = try await transformer.transform(data, config: config)
            let filename = try await manager.save(transformed)
            savedFilenames.append(filename)
        }
        
        // Verify all exist
        for filename in savedFilenames {
            let exists = await manager.exists(filename: filename)
            XCTAssertTrue(exists)
        }
        
        // Load all and verify they're different
        var loadedDataSizes: [Int] = []
        for filename in savedFilenames {
            let result = await manager.loadData(filename: filename)
            guard case .success(let data) = result else {
                XCTFail("Failed to load \(filename)")
                return
            }
            loadedDataSizes.append(data.count)
        }
        
        // All should have different sizes
        let uniqueSizes = Set(loadedDataSizes)
        XCTAssertEqual(uniqueSizes.count, savedFilenames.count)
    }
    
    func testLoadFromCacheAfterTransform() async throws {
        let originalData = createTestImageData(width: 2000, height: 1500)
        
        // Transform and save
        let config = ImageTransformConfig(cropRatio: 16/9, compressionQuality: 0.8)
        let transformed = try await transformer.transform(originalData, config: config)
        let filename = try await manager.save(transformed)
        
        // First load (from disk)
        let result1 = await manager.loadData(filename: filename)
        XCTAssertTrue(result1.isSuccess)
        
        // Second load (should be from cache)
        let result2 = await manager.loadData(filename: filename)
        XCTAssertTrue(result2.isSuccess)
        
        // Both should return same data
        if case .success(let data1) = result1,
           case .success(let data2) = result2 {
            XCTAssertEqual(data1, data2)
        }
    }
    
    func testDeleteAfterTransformAndSave() async throws {
        let data = createTestImageData(width: 1000, height: 1000)
        
        // Transform
        let config = ImageTransformConfig(cropRatio: 1.0, compressionQuality: 0.5)
        let transformed = try await transformer.transform(data, config: config)
        
        // Save
        let filename = try await manager.save(transformed)
        
        // Verify exists
        var exists = await manager.exists(filename: filename)
        XCTAssertTrue(exists)
        
        // Delete
        try await manager.delete(filename: filename)
        
        // Verify deleted
        exists = await manager.exists(filename: filename)
        XCTAssertFalse(exists)
    }
    
    func testCompleteUserWorkflow() async throws {
        // Simulate user selecting large photo from camera
        let photoData = createTestImageData(width: 4032, height: 3024)
        
        // User wants to crop to profile pic (1:1) and compress
        let profileConfig = ImageTransformConfig(
            cropRatio: 1.0,
            compressionQuality: 0.7,
            maxDimension: 512
        )
        let profilePic = try await transformer.transform(photoData, config: profileConfig)
        
        // Save profile pic
        let profileFilename = try await manager.save(profilePic, filename: "profile.jpg")
        
        // User also wants a banner (16:9)
        let bannerConfig = ImageTransformConfig(
            cropRatio: 16/9,
            compressionQuality: 0.8,
            maxDimension: 1920
        )
        let banner = try await transformer.transform(photoData, config: bannerConfig)
        
        // Save banner
        let bannerFilename = try await manager.save(banner, filename: "banner.jpg")
        
        // Verify both exist
        let profileExists = await manager.exists(filename: profileFilename)
        let bannerExists = await manager.exists(filename: bannerFilename)
        XCTAssertTrue(profileExists)
        XCTAssertTrue(bannerExists)
        
        // Load profile pic for display
        #if canImport(UIKit)
        let profileResult = await manager.loadUIImage(filename: profileFilename)
        guard case .success(let profileImage) = profileResult else {
            XCTFail("Failed to load profile")
            return
        }
        
        // Verify dimensions
        XCTAssertEqual(profileImage.size.width, 512, accuracy: 1.0)
        XCTAssertEqual(profileImage.size.height, 512, accuracy: 1.0)
        
        // Load banner
        let bannerResult = await manager.loadUIImage(filename: bannerFilename)
        guard case .success(let bannerImage) = bannerResult else {
            XCTFail("Failed to load banner")
            return
        }
        
        // Verify aspect ratio
        let ratio = bannerImage.size.width / bannerImage.size.height
        XCTAssertEqual(ratio, 16/9, accuracy: 0.01)
        #endif
        
        // User deletes old profile pic
        try await manager.delete(filename: profileFilename)
        let profileStillExists = await manager.exists(filename: profileFilename)
        XCTAssertFalse(profileStillExists)
    }
}

