//
//  ImageTransformConfig.swift
//  ImageManager
//
//  Created by NVR4GET
//

import Foundation
import CoreGraphics

/// Configuration for image transformations
public struct ImageTransformConfig {
    
    /// Crop ratio (e.g., 1.0 for 1:1, 16/9 for widescreen)
    public var cropRatio: CGFloat?
    
    /// JPEG compression quality (0.0 - 1.0)
    public var compressionQuality: CGFloat
    
    /// Maximum dimension (width or height) - resizes if larger
    public var maxDimension: CGFloat?
    
    /// Creates transform configuration
    /// - Parameters:
    ///   - cropRatio: Optional aspect ratio for cropping
    ///   - compressionQuality: JPEG quality (default: 0.8)
    ///   - maxDimension: Optional max size for resizing
    public init(
        cropRatio: CGFloat? = nil,
        compressionQuality: CGFloat = 0.8,
        maxDimension: CGFloat? = nil
    ) {
        self.cropRatio = cropRatio
        self.compressionQuality = compressionQuality
        self.maxDimension = maxDimension
    }
}
