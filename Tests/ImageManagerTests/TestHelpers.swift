//
//  TestHelpers.swift
//  ImageManagerTests
//
//  Created by NVR4GET
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Result Helpers

extension Result {
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    var isFailure: Bool {
        if case .failure = self { return true }
        return false
    }
}

// MARK: - Image Test Helpers

#if canImport(UIKit)
/// Creates test image data at 1x scale (no retina scaling)
func createTestImageData(width: CGFloat, height: CGFloat, color: UIColor = .red) -> Data {
    let size = CGSize(width: width, height: height)
    let renderer = UIGraphicsImageRenderer(size: size)
    let image = renderer.image { context in
        color.setFill()
        context.fill(CGRect(origin: .zero, size: size))
    }
    return image.jpegData(compressionQuality: 1.0)!
}
#elseif canImport(AppKit)
/// Creates test image data at 1x scale (no retina scaling)
func createTestImageData(width: CGFloat, height: CGFloat, color: NSColor = .red) -> Data {
    let size = NSSize(width: width, height: height)
    // Create image with explicit 1x scale
    let image = NSImage(size: size)
    
    // Lock focus and draw at 1x scale
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(width),
        pixelsHigh: Int(height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    
    image.addRepresentation(rep)
    
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    color.setFill()
    NSRect(origin: .zero, size: size).fill()
    NSGraphicsContext.restoreGraphicsState()
    
    return rep.representation(using: .jpeg, properties: [.compressionFactor: 1.0])!
}
#endif
