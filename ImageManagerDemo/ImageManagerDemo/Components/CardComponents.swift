//
//  CardComponents.swift
//  ImageManagerDemo
//
//  Created by NVR4GET on 13/12/2025.
//

import SwiftUI

// Platform-specific imports for image types
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Stat Card

/// A compact card displaying a single statistic with an icon
///
/// Used in the cache statistics section to show metrics like:
/// - Number of cached images
/// - Total cache size
/// - Load time performance
///
/// Features:
/// - Icon with gradient styling
/// - Large bold value text
/// - Small caption for the metric name
/// - Background tinted with the stat's color
struct StatCard: View {
    // MARK: - Properties
    
    /// The caption text shown below the value (e.g., "Images", "Cache Size")
    let title: String
    
    /// The main value to display (e.g., "6", "12.4 MB", "245ms")
    let value: String
    
    /// SF Symbol name for the icon
    let icon: String
    
    /// Color theme for the card (used for icon gradient and background tint)
    let color: Color
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon with gradient coloring
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color.gradient)
            
            // Main value (large and bold)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            // Caption label
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))  // Subtle background tint
        )
    }
}

// MARK: - Image Card

/// A card displaying an image thumbnail with metadata
///
/// Used in the image grid to show:
/// - Image preview with aspect-fill cropping
/// - Image title
/// - Load time performance metrics
/// - Cache hit indicator (checkmark vs download icon)
///
/// Features:
/// - Platform-specific image rendering (UIImage/NSImage)
/// - Loading placeholder with ProgressView
/// - Glassmorphic background styling
/// - Rounded corners for polish
///
/// - Parameters:
///   - item: The ImageItem containing image and metadata
///   - frameHeight: Maximum height for the image preview
struct ImageCard: View {
    // MARK: - Properties
    
    /// The image item to display
    let item: ImageItem
    
    /// Maximum height constraint for the image
    let frameHeight: CGFloat
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image preview or loading placeholder
            if let image = item.image {
                // Platform-specific image rendering
                #if canImport(UIKit)
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)     // Fill frame while maintaining aspect ratio
                    .frame(maxHeight: frameHeight)
                    .clipped()                            // Clip overflow
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                #elseif canImport(AppKit)
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxHeight: frameHeight)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                #endif
            } else {
                // Loading placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(.gray.opacity(0.2))
                    .frame(maxHeight: frameHeight)
                    .overlay {
                        ProgressView()
                    }
            }
            
            // Metadata section
            VStack(alignment: .leading, spacing: 4) {
                // Image title
                Text(item.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                // Performance metrics (if available)
                if let loadTime = item.loadTime {
                    HStack(spacing: 4) {
                        // Cache hit indicator icon
                        Image(systemName: item.fromCache ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                            .font(.caption2)
                        
                        // Load time in milliseconds
                        Text(String(format: "%.0fms", loadTime * 1000))
                            .font(.caption2)
                        
                        // Source label
                        Text(item.fromCache ? "cached" : "network")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)  // Glassmorphic background
        )
    }
}
