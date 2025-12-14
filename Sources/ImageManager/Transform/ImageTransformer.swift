//
//  ImageTransformer.swift
//  ImageManager
//
//  Created by NVR4GET
//

import Foundation
import CoreGraphics

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Standalone image transformer for cropping, resizing, and compression
///
/// Provides pure transformation logic separate from storage/caching.
/// Users can transform images independently and then save with ImageManager.
///
/// ## Usage
/// ```swift
/// let transformer = ImageTransformer()
/// let config = ImageTransformConfig(cropRatio: 1.0, compressionQuality: 0.7)
/// let transformed = try await transformer.transform(imageData, config: config)
/// ```
public final class ImageTransformer {
    
    public init() {}
    
    // MARK: - Transform Data
    
    /// Transforms image data with specified configuration
    /// - Parameters:
    ///   - data: Original image data
    ///   - config: Transform configuration
    /// - Returns: Transformed image data
    public func transform(_ data: Data, config: ImageTransformConfig) async throws -> Data {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else {
            throw ImageManagerError.invalidImageData
        }
        
        let transformed = try transformUIImage(image, config: config)
        guard let outputData = transformed.jpegData(compressionQuality: config.compressionQuality) else {
            throw ImageManagerError.transformFailed(underlyingError: NSError(domain: "ImageTransformer", code: -1))
        }
        return outputData
        
        #elseif canImport(AppKit)
        guard let image = NSImage(data: data) else {
            throw ImageManagerError.invalidImageData
        }
        
        let transformed = try transformNSImage(image, config: config)
        return try imageToJPEGData(transformed, quality: config.compressionQuality)
        
        #else
        throw ImageManagerError.unsupportedPlatform
        #endif
    }
    
    // MARK: - Transform Images
    
    #if canImport(UIKit)
    /// Transforms UIImage with specified configuration
    /// - Parameters:
    ///   - image: Original UIImage
    ///   - config: Transform configuration
    /// - Returns: Transformed image data
    public func transform(_ image: UIImage, config: ImageTransformConfig) async throws -> Data {
        let transformed = try transformUIImage(image, config: config)
        guard let data = transformed.jpegData(compressionQuality: config.compressionQuality) else {
            throw ImageManagerError.transformFailed(underlyingError: NSError(domain: "ImageTransformer", code: -1))
        }
        return data
    }
    
    private func transformUIImage(_ image: UIImage, config: ImageTransformConfig) throws -> UIImage {
        var result = image
        
        // Crop before resize - more efficient and preserves quality
        if let cropRatio = config.cropRatio {
            result = cropToRatio(result, aspectRatio: cropRatio)
        }
        
        // Apply resize if specified
        if let maxDim = config.maxDimension {
            result = resize(result, maxDimension: maxDim)
        }
        
        return result
    }
    
    private func cropToRatio(_ image: UIImage, aspectRatio: CGFloat) -> UIImage {
        let currentRatio = image.size.width / image.size.height
        
        // Already correct ratio (within tolerance)
        // 0.01 is roughly 1% - seems to work well in practice
        if abs(currentRatio - aspectRatio) < 0.01 {
            return image
        }
        
        // Build crop rect in points
        let cropRectPoints: CGRect
        if currentRatio > aspectRatio {
            // Image wider than target → crop width
            let newWidth = image.size.height * aspectRatio
            let xOffset = (image.size.width - newWidth) / 2
            cropRectPoints = CGRect(x: xOffset, y: 0, width: newWidth, height: image.size.height)
        } else {
            // Image taller than target → crop height
            let newHeight = image.size.width / aspectRatio
            let yOffset = (image.size.height - newHeight) / 2
            cropRectPoints = CGRect(x: 0, y: yOffset, width: image.size.width, height: newHeight)
        }
        
        // Convert points to pixels for CGImage cropping
        guard let cgImage = image.cgImage else { return image }
        let scale = image.scale
        let cropRectPixels = CGRect(
            x: cropRectPoints.origin.x * scale,
            y: cropRectPoints.origin.y * scale,
            width: cropRectPoints.size.width * scale,
            height: cropRectPoints.size.height * scale
        )
        
        guard let croppedCG = cgImage.cropping(to: cropRectPixels) else {
            return image
        }
        
        // Wrap back preserving original scale/orientation so logical size stays in points
        return UIImage(cgImage: croppedCG, scale: image.scale, orientation: image.imageOrientation)
    }
    
    private func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxCurrentDim = max(size.width, size.height)
        
        // Already smaller than max - no need to resize
        if maxCurrentDim <= maxDimension {
            return image
        }
        
        let scaleFactor = maxDimension / maxCurrentDim
        let newSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)
        
        // Force a 1x renderer so pixels == points, making sizes deterministic
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        // rendered.size is already in points; keep scale 1.0 so cgImage pixels == points
        // This ensures subsequent size reads return the expected logical sizes.
        if let cg = rendered.cgImage {
            return UIImage(cgImage: cg, scale: 1.0, orientation: .up)
        }
        return rendered
    }
    #endif
    
    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    /// Transforms NSImage with specified configuration
    /// - Parameters:
    ///   - image: Original NSImage
    ///   - config: Transform configuration
    /// - Returns: Transformed image data
    public func transform(_ image: NSImage, config: ImageTransformConfig) async throws -> Data {
        let transformed = try transformNSImage(image, config: config)
        return try imageToJPEGData(transformed, quality: config.compressionQuality)
    }
    
    private func transformNSImage(_ image: NSImage, config: ImageTransformConfig) throws -> NSImage {
        var result = image
        
        // Apply crop if specified
        if let cropRatio = config.cropRatio {
            result = cropToRatio(result, aspectRatio: cropRatio)
        }
        
        // Apply resize if specified
        if let maxDim = config.maxDimension {
            result = resize(result, maxDimension: maxDim)
        }
        
        return result
    }
    
    private func cropToRatio(_ image: NSImage, aspectRatio: CGFloat) -> NSImage {
        let currentRatio = image.size.width / image.size.height
        
        if abs(currentRatio - aspectRatio) < 0.01 {
            return image
        }
        
        var cropRect: CGRect
        
        if currentRatio > aspectRatio {
            let newWidth = image.size.height * aspectRatio
            let xOffset = (image.size.width - newWidth) / 2
            cropRect = CGRect(x: xOffset, y: 0, width: newWidth, height: image.size.height)
        } else {
            let newHeight = image.size.width / aspectRatio
            let yOffset = (image.size.height - newHeight) / 2
            cropRect = CGRect(x: 0, y: yOffset, width: image.size.width, height: newHeight)
        }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)?.cropping(to: cropRect) else {
            return image
        }
        
        let newImage = NSImage(cgImage: cgImage, size: NSSize(width: cropRect.width, height: cropRect.height))
        return newImage
    }
    
    private func resize(_ image: NSImage, maxDimension: CGFloat) -> NSImage {
        let size = image.size
        let maxCurrentDim = max(size.width, size.height)
        
        if maxCurrentDim <= maxDimension {
            return image
        }
        
        let scale = maxDimension / maxCurrentDim
        let newSize = NSSize(width: size.width * scale, height: size.height * scale)
        
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize))
        newImage.unlockFocus()
        
        return newImage
    }
    
    private func imageToJPEGData(_ image: NSImage, quality: CGFloat) throws -> Data {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ImageManagerError.transformFailed(underlyingError: NSError(domain: "ImageTransformer", code: -1))
        }
        
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let data = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: quality]) else {
            throw ImageManagerError.transformFailed(underlyingError: NSError(domain: "ImageTransformer", code: -1))
        }
        
        return data
    }
    #endif
    
    // TODO: Consider adding support for other formats (PNG, HEIC) beyond JPEG
    // Currently only outputs JPEG for simplicity
}

