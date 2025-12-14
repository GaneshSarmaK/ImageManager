//
//  ImageItem.swift
//  ImageManagerDemo
//
//  Created by NVR4GET on 13/12/2025.
//

import Foundation

// Platform-specific imports for image types
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Model representing a cached image with associated metadata
///
/// This model stores information about an image managed by `ImageManager`,
/// including performance metrics like load time and cache status. It uses
/// platform-specific image types to support both iOS/iPadOS (UIImage) and
/// macOS (NSImage).
///
/// - Note: Conforms to `Identifiable` for use in SwiftUI ForEach loops
struct ImageItem: Identifiable {
    // MARK: - Properties
    
    /// Unique identifier for this image item
    let id = UUID()
    
    /// Filename used to store and retrieve the image from ImageManager
    let filename: String
    
    /// Human-readable title displayed in the UI
    let title: String
    
    /// The actual image data, platform-specific:
    /// - iOS/iPadOS: `UIImage`
    /// - macOS: `NSImage`
    #if canImport(UIKit)
    var image: UIImage?
    #elseif canImport(AppKit)
    var image: NSImage?
    #endif
    
    /// Time taken to load this image, in seconds
    /// - Note: Multiply by 1000 to display in milliseconds
    var loadTime: TimeInterval?
    
    /// Whether this image was loaded from cache (true) or network (false)
    /// - Used to display cache hit indicators in the UI
    var fromCache: Bool = false
}
