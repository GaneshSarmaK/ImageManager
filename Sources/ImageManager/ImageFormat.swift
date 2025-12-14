//
//  ImageFormat.swift
//  ImageManager
//
//  Created by NVR4GET
//

import Foundation

/// Supported image formats for saving
public enum ImageFormat {
    case jpeg
    case png
    case heic
    case gif
    case webp
    case custom(String)
    
    /// File extension for the format
    var fileExtension: String {
        switch self {
        case .jpeg:
            return "jpg"
        case .png:
            return "png"
        case .heic:
            return "heic"
        case .gif:
            return "gif"
        case .webp:
            return "webp"
        case .custom(let fileFormat):
            // Remove leading dot if user provided it
            return fileFormat.hasPrefix(".") ? String(fileFormat.dropFirst()) : fileFormat
        }
    }
}
