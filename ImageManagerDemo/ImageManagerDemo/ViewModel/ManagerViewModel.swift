//
//  ManagerViewModel.swift
//  ImageManagerDemo
//
//  Created by NVR4GET on 13/12/2025.
//

import SwiftUI
import ImageManager
import Foundation

/// ViewModel managing ImageManager demo operations and application state
///
/// This ViewModel serves as the business logic layer for the ImageManager demo app.
/// It handles:
/// - Loading sample images from Unsplash API
/// - Applying various image transformations (crop, resize, compress)
/// - Reloading images from cache to demonstrate performance
/// - Managing cache statistics and metrics
/// - Error handling and user feedback
///
/// The ViewModel uses the `@Observable` macro for automatic SwiftUI updates.
@Observable
class ManagerViewModel {
    // MARK: - Published State
    
    /// Array of all loaded and transformed images
    var images: [ImageItem] = []
    
    /// Whether sample images are currently being downloaded
    var isLoading = false
    
    /// Whether image transformations are currently being processed
    var isTransforming = false
    
    /// Number of images currently cached (updated after operations)
    var cachedImagesCount = 0
    
    /// Total size of cached images in bytes
    var cacheSize: Int64 = 0
    
    /// Time taken for the last operation (load/reload/transform), in seconds
    var lastLoadTime: TimeInterval = 0
    
    /// Error message to display to the user, if any
    var errorMessage: String?
    
    /// Counter for generating unique filenames for loaded images
    var totalImageCount: Int = 1
    
    // MARK: - Private Dependencies
    
    /// ImageManager instance for caching operations
    /// - Note: Configured with 100MB cache and 50 item limit
    @ObservationIgnored private let imageManager: ImageManager
    
    /// ImageTransformer instance for image manipulation
    @ObservationIgnored private let transformer: ImageTransformer
    
    /// Sample image URLs from Unsplash (free to use, no API key required)
    /// - Note: Using 800px width for reasonable quality and download speed
    @ObservationIgnored private let sampleImageURLs = [
        "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=800&q=80", // Mountain landscape
        "https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=800&q=80", // Forest scene
        "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&q=80", // Nature path
        "https://images.unsplash.com/photo-1426604966848-d7adac402bff?w=800&q=80", // Lake view
        "https://images.unsplash.com/photo-1472214103451-9374bd1c798e?w=800&q=80", // Road scene
        "https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=800&q=80", // Desert landscape
    ]
    
    // MARK: - Initialization
    
    /// Initializes the ViewModel with ImageManager and ImageTransformer
    ///
    /// Sets up:
    /// - ImageManager with 100MB cache size and 50 item limit
    /// - Custom storage directory in Documents/ImageManagerDemo
    /// - ImageTransformer for image manipulation
    /// - Initial cache statistics
    init() {
        // Configure ImageManager with custom settings
        // 100MB should be enough for the demo, but adjust as needed
        let config = ImageManagerConfig(
            maxCacheSize: 100_000_000,  // 100MB cache limit
            maxCacheCount: 50,            // Maximum 50 cached images
            baseURL: FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("ImageManagerDemo")  // Custom subdirectory
        )
        self.imageManager = ImageManager(config: config)
        self.transformer = ImageTransformer()
        
        // Calculate initial cache statistics
        updateCacheStats()
    }
    
    // MARK: - Computed Properties
    
    /// Formatted cache size string (e.g., "12.4 MB", "3.2 KB")
    var cacheSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: cacheSize, countStyle: .file)
    }
    
    /// Formatted load time string in milliseconds (e.g., "245ms")
    /// - Returns: Formatted string, or "—" if no operations have been performed
    var lastLoadTimeFormatted: String {
        if lastLoadTime == 0 {
            return "—"
        }
        return String(format: "%.0fms", lastLoadTime * 1000)
    }
    
    // MARK: - Public Methods
    
    /// Downloads and caches sample images from Unsplash
    ///
    /// This method demonstrates the full image loading pipeline:
    /// 1. Download image data from network
    /// 2. Save to ImageManager (writes to disk)
    /// 3. Load back to verify caching (loads from memory cache)
    /// 4. Track performance metrics
    ///
    /// - Note: Uses platform-specific image loading (UIImage on iOS, NSImage on macOS)
    func loadSampleImages() async {
        isLoading = true
        errorMessage = nil
        let startTime = Date()
        
        do {
            var loadedImages: [ImageItem] = []
            
            // Process each sample image URL
            for urlString in sampleImageURLs {
                guard let url = URL(string: urlString) else { continue }
                
                let itemStartTime = Date()
                
                // Step 1: Download image data from Unsplash
                let (data, _) = try await URLSession.shared.data(from: url)
                
                // Step 2: Save to ImageManager (auto-detects format and caches)
                let filename = try await imageManager.save(data, filename: "sample_\(totalImageCount).jpg")
                
                // Step 3: Load back using platform-specific method
                #if canImport(UIKit)
                let result = await imageManager.loadUIImage(filename: filename)
                #elseif canImport(AppKit)
                let result = await imageManager.loadNSImage(filename: filename)
                #endif
                
                // Calculate load time for this image
                let loadTime = Date().timeIntervalSince(itemStartTime)
                
                // Step 4: Add to array if successful
                if case .success(let image) = result {
                    totalImageCount += 1
                    loadedImages.append(ImageItem(
                        filename: filename,
                        title: "Image \(totalImageCount)",
                        image: image,
                        loadTime: loadTime,
                        fromCache: false  // This is a fresh network load
                    ))
                }
            }
            
            // Append all newly loaded images to the collection
            images.append(contentsOf: loadedImages)
            
            // Record total operation time
            lastLoadTime = Date().timeIntervalSince(startTime)
            
            // Update cache statistics
            updateCacheStats()
            
        } catch {
            // Display error to user
            errorMessage = "Failed to load images: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Applies different transformations to the first 3 loaded images
    ///
    /// Demonstrates ImageTransformer capabilities by applying:
    /// - **Image 1**: Square crop (1:1 aspect ratio) at 80% quality
    /// - **Image 2**: Widescreen crop (16:9) + resize to 800px at 70% quality
    /// - **Image 3**: Simple resize to 600px at 90% quality
    ///
    /// - Note: Requires at least one image to be loaded first
    func testTransformations() async {
        // Ensure we have images to transform
        guard !images.isEmpty else {
            errorMessage = "Load sample images first"
            return
        }
        
        isTransforming = true
        errorMessage = nil
        
        do {
            var transformedImages: [ImageItem] = []
            
            // Only transform the first 3 images to keep demo concise
            let testImages = Array(images.prefix(3))
            
            for (index, item) in testImages.enumerated() {
                // Load original image data
                let dataResult = await imageManager.loadData(filename: item.filename)
                guard case .success(let data) = dataResult else { continue }
                
                let startTime = Date()
                
                // Apply different transformation based on index
                let config: ImageTransformConfig
                switch index {
                case 0:
                    // Square crop for thumbnails/avatars
                    config = ImageTransformConfig(cropRatio: 1.0, compressionQuality: 0.8)
                case 1:
                    // Widescreen crop for banners/headers
                    config = ImageTransformConfig(cropRatio: 16/9, compressionQuality: 0.7, maxDimension: 800)
                default:
                    // Just resize without cropping
                    config = ImageTransformConfig(compressionQuality: 0.9, maxDimension: 600)
                }
                
                // Perform transformation
                let transformedData = try await transformer.transform(data, config: config)
                
                // Save transformed image with unique filename
                let filename = try await imageManager.save(transformedData, filename: "transformed_\(index).jpg")
                
                // Load back using platform-specific method
                #if canImport(UIKit)
                let result = await imageManager.loadUIImage(filename: filename)
                #elseif canImport(AppKit)
                let result = await imageManager.loadNSImage(filename: filename)
                #endif
                
                let loadTime = Date().timeIntervalSince(startTime)
                
                // Add to results with descriptive title
                if case .success(let image) = result {
                    let title: String
                    switch index {
                    case 0: title = "Square (1:1)"
                    case 1: title = "Wide (16:9)"
                    default: title = "Resized (600px)"
                    }
                    
                    transformedImages.append(ImageItem(
                        filename: filename,
                        title: title,
                        image: image,
                        loadTime: loadTime,
                        fromCache: false
                    ))
                }
            }
            
            // Append transformed images to the main collection
            images.append(contentsOf: transformedImages)
            
            // Update cache statistics
            updateCacheStats()
            
        } catch {
            errorMessage = "Transformation failed: \(error.localizedDescription)"
        }
        
        isTransforming = false
    }
    
    /// Reloads all currently displayed images from cache
    ///
    /// This demonstrates cache performance by:
    /// 1. Reloading each image from ImageManager
    /// 2. Measuring load time (should be <10ms from cache)
    /// 3. Marking images as cache hits for UI display
    ///
    /// - Note: Compare load times with initial network loads to see ~100x speedup
    func reloadFromCache() async {
        guard !images.isEmpty else {
            errorMessage = "No images to reload"
            return
        }
        
        let startTime = Date()
        var reloadedImages: [ImageItem] = []
        
        // Reload each image from cache
        for item in images {
            let itemStartTime = Date()
            
            // Load using platform-specific method
            #if canImport(UIKit)
            let result = await imageManager.loadUIImage(filename: item.filename)
            #elseif canImport(AppKit)
            let result = await imageManager.loadNSImage(filename: item.filename)
            #endif
            
            let loadTime = Date().timeIntervalSince(itemStartTime)
            
            if case .success(let image) = result {
                reloadedImages.append(ImageItem(
                    filename: item.filename,
                    title: item.title,
                    image: image,
                    loadTime: loadTime,
                    fromCache: true  // Mark as cache hit
                ))
            }
        }
        
        // Replace images array with reloaded versions
        images = reloadedImages
        lastLoadTime = Date().timeIntervalSince(startTime)
    }
    
    /// Clears all cached images and resets statistics
    ///
    /// This method:
    /// 1. Calls ImageManager to clear memory and disk cache
    /// 2. Removes all images from the UI
    /// 3. Resets all statistics to zero
    /// 4. Clears any error messages
    func clearCache() {
        imageManager.clearCache()
        images = []
        updateCacheStats()
        lastLoadTime = 0
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    /// Updates cache statistics by calculating image count and total size
    ///
    /// This runs asynchronously in the background to avoid blocking the UI.
    /// It loads the raw data for each image to calculate the total cache size.
    private func updateCacheStats() {
        cachedImagesCount = images.count
        
        // Calculate total cache size asynchronously
        Task {
            var totalSize: Int64 = 0
            
            // Sum up the size of all cached images
            for item in images {
                let result = await imageManager.loadData(filename: item.filename)
                if case .success(let data) = result {
                    totalSize += Int64(data.count)
                }
            }
            
            // Update cache size on main thread
            await MainActor.run {
                self.cacheSize = totalSize
            }
        }
    }
}
