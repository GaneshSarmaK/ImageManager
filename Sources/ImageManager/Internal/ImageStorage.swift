//
//  ImageStorage.swift
//  ImageManager
//
//  Created by NVR4GET
//

import Foundation

/// Internal storage layer for disk-based image persistence
internal final class ImageStorage {
    
    // MARK: - Properties
    
    private let baseURL: URL
    private let fileManager: FileManager
    
    // MARK: - Initialization
    
    init(baseURL: URL, fileManager: FileManager = .default) {
        self.baseURL = baseURL
        self.fileManager = fileManager
        
        // Ensure base directory exists
        try? fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }
    
    // MARK: - Storage Operations
    
    /// Saves data to disk
    /// - Parameters:
    ///   - data: Data to save
    ///   - filename: Filename to use
    /// - Returns: Full URL of saved file
    func save(_ data: Data, filename: String) async throws -> URL {
        let fileURL = baseURL.appendingPathComponent(filename)
        
        do {
            // Using .atomic to prevent partial writes if app crashes
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            throw ImageManagerError.saveFailed(underlyingError: error)
        }
    }
    
    /// Loads data from disk
    /// - Parameter filename: Filename to load
    /// - Returns: File data
    func load(filename: String) async throws -> Data {
        let fileURL = baseURL.appendingPathComponent(filename)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw ImageManagerError.fileNotFound(filename: filename)
        }
        
        do {
            return try Data(contentsOf: fileURL)
        } catch {
            throw ImageManagerError.loadFailed(underlyingError: error)
        }
    }
    
    /// Deletes file from disk
    /// - Parameter filename: Filename to delete
    func delete(filename: String) async throws {
        let fileURL = baseURL.appendingPathComponent(filename)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw ImageManagerError.fileNotFound(filename: filename)
        }
        
        do {
            try fileManager.removeItem(at: fileURL)
        } catch {
            throw ImageManagerError.deleteFailed(underlyingError: error)
        }
    }
    
    /// Checks if file exists
    /// - Parameter filename: Filename to check
    /// - Returns: True if file exists
    func exists(filename: String) -> Bool {
        let fileURL = baseURL.appendingPathComponent(filename)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    /// Gets URL for filename
    /// - Parameter filename: Filename
    /// - Returns: Full URL
    func url(for filename: String) -> URL {
        return baseURL.appendingPathComponent(filename)
    }
}
