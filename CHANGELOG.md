# Changelog

## [Unreleased]

### Planned
- Hot cache optimization: Store pre-decoded images (UIImage/NSImage) for instant access
- Support for PNG, HEIC, and other image formats in ImageTransformer
- Platform-specific test adjustments for macOS image scaling differences

## [1.0.0] - 2025-12-14

### Added
- Initial release of ImageManager
- NSCache-based memory caching with LRU eviction
- Persistent disk storage with configurable location
- Type-safe API with separate methods per image type (`loadUIImage`, `loadNSImage`, `loadCGImage`)
- Async/await support for all operations
- Automatic memory management with memory warning handling
- ImageTransformer for image manipulation:
  - Crop to aspect ratio
  - Resize to max dimension
  - JPEG compression with quality control
- Platform support for iOS 13+, macOS 10.15+, iPadOS 13+
- Configurable cache size and count limits
- Error handling with `LocalizedError` conformance
- Demo application showcasing package features

### Known Issues
- ImageTransformer supports JPEG format only (PNG, HEIC support planned)
- Some transformation tests fail on macOS due to image scaling/DPI differences
- NSCache stores images as NSData requiring decoding on fetch (hot cache optimization planned)

[1.0.0]: https://github.com/NVR4GET/ImageManager/releases/tag/v1.0.0
