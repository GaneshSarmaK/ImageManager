//
//  ImageCache.swift
//  ImageManager
//
//  Created by NVR4GET
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Internal cache layer using NSCache for automatic LRU eviction and memory management
internal final class ImageCache: @unchecked Sendable {
    
    // MARK: - Properties
    
    // NSCache is thread-safe, so @unchecked Sendable is safe here
    private nonisolated(unsafe) let cache: NSCache<NSString, NSData>
    
    // MARK: - Initialization
    
    init(maxSize: Int, maxCount: Int) {
        self.cache = NSCache<NSString, NSData>()
        self.cache.totalCostLimit = maxSize
        self.cache.countLimit = maxCount
        
        // Auto-clear on memory warning
        // NSCache handles this automatically, but we listen for explicit warnings too
#if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clear()
        }
#endif
    }
    
    // MARK: - Cache Operations
    
    /// Retrieves data from cache
    /// - Parameter key: Cache key (typically filename)
    /// - Returns: Cached data if found, nil otherwise
    func get(key: String) -> Data? {
        return cache.object(forKey: key as NSString) as Data?
    }
    
    /// Stores data in cache
    /// - Parameters:
    ///   - key: Cache key (typically filename)
    ///   - data: Data to cache
    func set(key: String, data: Data) {
        cache.setObject(data as NSData, forKey: key as NSString, cost: data.count)
    }
    
    /// Removes specific item from cache
    /// - Parameter key: Cache key to remove
    func remove(key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    /// Clears entire cache
    func clear() {
        cache.removeAllObjects()
    }

}


