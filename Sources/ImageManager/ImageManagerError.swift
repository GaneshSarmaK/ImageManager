//
//  ImageManagerError.swift
//  ImageManager
//
//  Created by NVR4GET
//

import Foundation

/// Errors that can occur during image operations
public enum ImageManagerError: Error, LocalizedError {
    
    case fileNotFound(filename: String)
    case invalidImageData
    case saveFailed(underlyingError: Error)
    case loadFailed(underlyingError: Error)
    case deleteFailed(underlyingError: Error)
    case transformFailed(underlyingError: Error)
    case unsupportedPlatform
    
    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Image file '\(filename)' not found"
        case .invalidImageData:
            return "Could not decode image data"
        case .saveFailed(let error):
            return "Failed to save image: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load image: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete image: \(error.localizedDescription)"
        case .transformFailed(let error):
            return "Failed to transform image: \(error.localizedDescription)"
        case .unsupportedPlatform:
            return "This operation is not supported on the current platform"
        }
    }
}
