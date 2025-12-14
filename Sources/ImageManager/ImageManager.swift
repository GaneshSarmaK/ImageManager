//
//  ImageManager.swift
//  ImageManager
//
//  Created by NVR4GET
//

import Foundation

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
#endif

/// Main image management system with caching and storage
///
/// Provides a clean API for saving, loading, and deleting images with automatic
/// caching (NSCache-based LRU) and disk persistence.
///
/// ## Features
/// - Memory cache with automatic LRU eviction
/// - Disk-based storage with configurable location
/// - Auto-generates UUID filenames if not provided
/// - Type-safe load methods (no casting required)
/// - Async operations for large images
///
/// ## Usage
/// ```swift
/// let config = ImageManagerConfig(maxCacheSize: 250_000_000)
/// let manager = ImageManager(config: config)
///
/// // Save
/// let filename = try await manager.save(imageData)
///
/// // Load as UIImage
/// let result = await manager.loadUIImage(filename: filename)
/// ```
public final class ImageManager {
    
    // MARK: - Properties
    
    private let cache: ImageCache
    private let storage: ImageStorage
    private let config: ImageManagerConfig
    
    // MARK: - Initialization
    
    /// Creates an ImageManager with the specified configuration
    /// - Parameter config: Configuration (defaults to standard config)
    public init(config: ImageManagerConfig = ImageManagerConfig()) {
        self.config = config
        self.cache = ImageCache(maxSize: config.maxCacheSize, maxCount: config.maxCacheCount)
        self.storage = ImageStorage(baseURL: config.baseURL)
    }
    
    // MARK: - Save Operations
    
    /// Saves image data to disk and cache
    /// - Parameters:
    ///   - data: Image data to save
    ///   - filename: Optional filename (auto-generates UUID if nil)
    ///   - format: Image format for auto-generated filename (default: .jpeg)
    /// - Returns: Filename used for storage
    public func save(_ data: Data, filename: String? = nil, format: ImageFormat = .jpeg) async throws -> String {
        // Generate filename if not provided
        let finalFilename: String
        if let filename = filename {
            finalFilename = filename
        } else {
            // Using UUID to avoid collisions - could add timestamp if needed
            finalFilename = "\(UUID().uuidString).\(format.fileExtension)"
        }
        
        // Save to disk first (fail fast if disk is full)
        _ = try await storage.save(data, filename: finalFilename)
        
        // Cache the data for quick access
        cache.set(key: finalFilename, data: data)
        
        return finalFilename
    }

    
    // MARK: - Load Operations (Type-Safe)
    
    /// Loads image data from cache or disk
    /// - Parameter filename: Filename to load
    /// - Returns: Result with Data or error
    public func loadData(filename: String) async -> Result<Data, ImageManagerError> {
        // Check cache first - much faster than disk I/O
        if let cachedData = cache.get(key: filename) {
            return .success(cachedData)
        }
        
        // Load from disk
        do {
            let data = try await storage.load(filename: filename)
            // Cache for next time (async, won't block)
            cache.set(key: filename, data: data)
            return .success(data)
        } catch let error as ImageManagerError {
            // Already our error type, pass through
            return .failure(error)
        } catch {
            // Wrap unexpected errors
            return .failure(.loadFailed(underlyingError: error))
        }
    }
    
    #if canImport(UIKit)
    /// Loads image as UIImage from cache or disk (iOS/iPadOS)
    /// - Parameter filename: Filename to load
    /// - Returns: Result with UIImage or error
    public func loadUIImage(filename: String) async -> Result<UIImage, ImageManagerError> {
        let dataResult = await loadData(filename: filename)
        
        switch dataResult {
        case .success(let data):
            guard let image = UIImage(data: data) else {
                return .failure(.invalidImageData)
            }
            return .success(image)
        case .failure(let error):
            return .failure(error)
        }
    }
    #endif
    
    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    /// Loads image as NSImage from cache or disk (macOS)
    /// - Parameter filename: Filename to load
    /// - Returns: Result with NSImage or error
    public func loadNSImage(filename: String) async -> Result<NSImage, ImageManagerError> {
        let dataResult = await loadData(filename: filename)
        
        switch dataResult {
        case .success(let data):
            guard let image = NSImage(data: data) else {
                return .failure(.invalidImageData)
            }
            return .success(image)
        case .failure(let error):
            return .failure(error)
        }
    }
    #endif
    
    /// Loads image as CGImage from cache or disk
    /// - Parameter filename: Filename to load
    /// - Returns: Result with CGImage or error
    public func loadCGImage(filename: String) async -> Result<CGImage, ImageManagerError> {
        let dataResult = await loadData(filename: filename)
        
        switch dataResult {
        case .success(let data):
            #if canImport(UIKit)
            guard let uiImage = UIImage(data: data),
                  let cgImage = uiImage.cgImage else {
                return .failure(.invalidImageData)
            }
            return .success(cgImage)
            #elseif canImport(AppKit)
            guard let nsImage = NSImage(data: data),
                  let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                return .failure(.invalidImageData)
            }
            return .success(cgImage)
            #else
            return .failure(.unsupportedPlatform)
            #endif
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Delete Operations
    
    /// Deletes image from both cache and disk
    /// - Parameter filename: Filename to delete
    public func delete(filename: String) async throws {
        // Remove from cache
        cache.remove(key: filename)
        
        // Remove from disk
        try await storage.delete(filename: filename)
    }
    
    // MARK: - Query Operations
    
    /// Checks if image exists in storage
    /// - Parameter filename: Filename to check
    /// - Returns: True if file exists
    public func exists(filename: String) async -> Bool {
        return storage.exists(filename: filename)
    }
    
    // MARK: - Cache Management
    
    /// Clears entire memory cache
    public func clearCache() {
        cache.clear()
    }
    
    /// Removes specific item from cache
    /// - Parameter filename: Filename to remove from cache
    public func removeFromCache(filename: String) {
        cache.remove(key: filename)
    }
}

