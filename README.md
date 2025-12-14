# ImageManager

A lightweight, type-safe Swift package for image storage and caching with automatic memory management.

## Features

- ✅ **Memory Cache** - NSCache-based LRU eviction with configurable size (default: 250MB)
- ✅ **Disk Storage** - Persistent storage with configurable location
- ✅ **Type-Safe API** - No casting required with separate methods per type
- ✅ **Async Operations** - Built for modern Swift with async/await
- ✅ **Auto Memory Management** - Clears cache on memory warnings
- ✅ **Separate Transformer** - Independent image transformation logic
- ✅ **Platform Support** - iOS 13+, macOS 10.15+, iPadOS 13+

## ⚠️ Important Notes

> [!WARNING]
> **Image Transformation Format Limitation**
> 
> The `ImageTransformer` currently supports **JPEG format only** for transformation and compression operations. Other formats (PNG, HEIC, etc.) are not supported at this time.
> 
> If you need to transform non-JPEG images, convert them to JPEG first before applying transformations.

> [!NOTE]
> **Work in Progress: Hot Cache Optimization**
> 
> Currently, `NSCache` stores images as `NSData` (encoded), which requires decoding on every fetch. This adds a small performance overhead.
> 
> **Upcoming Feature**: A hot cache implementation that stores pre-decoded images (UIImage/NSImage) for instant access without decoding overhead. This will significantly improve cache hit performance for frequently accessed images.
> 
> Track progress: [Feature planned for v1.1.0]

> [!CAUTION]
> **Known Issue: Transformation Tests Failing on macOS**
> 
> Some image transformation tests are currently failing, potentially due to macOS-specific image scaling behavior and DPI differences between UIKit (iOS) and AppKit (macOS).
> 
> The core transformation logic works correctly in production, but test assertions for expected dimensions may need platform-specific adjustments. This is under investigation.

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/GaneshSarmaK/ImageManager.git", from: "1.0.0")
]
```

Or in Xcode: **File > Add Package Dependencies...**

## Usage

### Basic Operations

```swift
import ImageManager

// Initialize with default config (250MB cache)
let manager = ImageManager()

// Or with custom config
let config = ImageManagerConfig(
    maxCacheSize: 100_000_000,  // 100MB
    maxCacheCount: 50,
    baseURL: customDirectory
)
let manager = ImageManager(config: config)

// Save image (auto-generates UUID filename)
let filename = try await manager.save(imageData)

// Save with custom filename
let filename = try await manager.save(imageData, filename: "profile.jpg")

// Load as Data
let result = await manager.loadData(filename: filename)
switch result {
case .success(let data):
    print("Loaded \(data.count) bytes")
case .failure(let error):
    print("Error: \(error.localizedDescription)")
}

// Load as UIImage (iOS/iPadOS)
let imageResult = await manager.loadUIImage(filename: filename)
if case .success(let image) = imageResult {
    imageView.image = image
}

// Load as NSImage (macOS)
let imageResult = await manager.loadNSImage(filename: filename)

// Load as CGImage
let cgImageResult = await manager.loadCGImage(filename: filename)

// Delete
try await manager.delete(filename: filename)

// Check if exists
let exists = await manager.exists(filename: filename)

// Cache management
manager.clearCache()
manager.removeFromCache(filename: filename)
```

### Image Transformation

```swift
import ImageManager

let transformer = ImageTransformer()

// Crop to square (1:1)
let config = ImageTransformConfig(
    cropRatio: 1.0,
    compressionQuality: 0.8
)
let transformed = try await transformer.transform(imageData, config: config)

// Resize to max 1024px
let config = ImageTransformConfig(
    maxDimension: 1024,
    compressionQuality: 0.7
)
let resized = try await transformer.transform(imageData, config: config)

// Combine: crop to 16:9 and resize
let config = ImageTransformConfig(
    cropRatio: 16/9,
    compressionQuality: 0.8,
    maxDimension: 1920
)
let processed = try await transformer.transform(imageData, config: config)

// Transform and save
let manager = ImageManager()
let filename = try await manager.save(processed)
```

### Platform-Specific Loading

```swift
#if canImport(UIKit)
// iOS/iPadOS
let result = await manager.loadUIImage(filename: "photo.jpg")
#elseif canImport(AppKit)
// macOS
let result = await manager.loadNSImage(filename: "photo.jpg")
#endif

// Or use CGImage (works on all platforms)
let cgResult = await manager.loadCGImage(filename: "photo.jpg")
```

## Architecture

```
ImageManager
├── ImageManager (main API)
│   ├── save/load/delete operations
│   └── type-safe load methods
├── ImageCache (NSCache wrapper)
│   ├── LRU eviction
│   └── auto memory management
├── ImageStorage (disk persistence)
│   └── configurable base directory
└── ImageTransformer (separate)
    ├── crop to aspect ratio
    ├── resize to max dimension
    └── JPEG compression
```

## Type-Safe API

No more casting! Each return type has its own method:

```swift
// Old way (requires casting)
let image = manager.load(filename) as! UIImage

// New way (type-safe)
let result = await manager.loadUIImage(filename: filename)
if case .success(let image) = result {
    // image is UIImage, no casting needed
}
```

## Configuration

```swift
public struct ImageManagerConfig {
    var maxCacheSize: Int       // bytes (default: 250MB)
    var maxCacheCount: Int      // items (default: 100)
    var baseURL: URL            // storage location (default: documents)
}
```

## Error Handling

All errors conform to `LocalizedError`:

```swift
public enum ImageManagerError: Error {
    case fileNotFound(filename: String)
    case invalidImageData
    case saveFailed(underlyingError: Error)
    case loadFailed(underlyingError: Error)
    case deleteFailed(underlyingError: Error)
    case transformFailed(underlyingError: Error)
    case unsupportedPlatform
}
```

## Requirements

- iOS 13.0+ / macOS 10.15+ / iPadOS 13.0+
- Swift 6.0+

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

NVR4GET
