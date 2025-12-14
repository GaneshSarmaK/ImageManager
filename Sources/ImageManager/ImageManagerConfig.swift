//
//  ImageManagerConfig.swift
//  ImageManager
//
//  Created by NVR4GET
//

import Foundation

/// Configuration for ImageManager instance
public struct ImageManagerConfig {
    
    // MARK: - Cache Settings
    
    /// Maximum cache size in bytes (default: 250MB)
    public var maxCacheSize: Int
    
    /// Maximum number of cached items (default: 100)
    public var maxCacheCount: Int
    
    // MARK: - Storage Settings
    
    /// Base URL for image storage (default: documents directory)
    public var baseURL: URL
    
    // MARK: - Initialization
    
    /// Creates a configuration with default or custom values
    /// - Parameters:
    ///   - maxCacheSize: Maximum cache size in bytes (default: 250MB)
    ///   - maxCacheCount: Maximum number of items to cache (default: 100)
    ///   - baseURL: Base directory for storage (default: documents directory)
    public init(
        maxCacheSize: Int = 250_000_000,  // 250MB - reasonable default for most apps
        maxCacheCount: Int = 100,
        baseURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    ) {
        self.maxCacheSize = maxCacheSize
        self.maxCacheCount = maxCacheCount
        self.baseURL = baseURL
    }
}
