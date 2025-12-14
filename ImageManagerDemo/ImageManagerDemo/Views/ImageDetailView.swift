//
//  ImageDetailView.swift
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

// MARK: - Image Detail View

/// Full-screen sheet view for displaying image details and metadata
///
/// Presented as a sheet when the user taps an image in the grid. Shows:
/// - Full-size image preview
/// - Image metadata (filename, dimensions, load time)
/// - Cache performance metrics
/// - Source indicator (cache hit vs network load)
///
/// Features:
/// - Resizable sheet (.medium and .large detents)
/// - Scrollable content for long images
/// - Platform-specific image rendering
/// - "Done" button in navigation bar
/// - Drag indicator for dismissal
struct ImageDetailView: View {
    // MARK: - Properties
    
    /// The image item to display in detail
    let item: ImageItem
    
    /// Environment value for dismissing the sheet
    @Environment(\.dismiss) var dismiss
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Full-size image preview
                    imagePreview
                    
                    // Metadata section
                    metadataSection
                }
                .padding(.bottom)
            }
            .navigationTitle("Image Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])  // Resizable sheet
        .presentationDragIndicator(.visible)      // Show drag handle
    }
    
    // MARK: - Subviews
    
    /// Full-size image preview with platform-specific rendering
    private var imagePreview: some View {
        Group {
            if let image = item.image {
                // Render image based on platform
                #if canImport(UIKit)
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)  // Fit entire image in view
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding()
                #elseif canImport(AppKit)
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding()
                #endif
            } else {
                // Loading placeholder (shouldn't normally happen)
                ProgressView()
                    .frame(height: 400)
            }
        }
    }
    
    /// Metadata section with image details
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Image title
            Text(item.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Divider()
            
            // Metadata rows
            VStack(alignment: .leading, spacing: 12) {
                // Filename
                DetailRow(
                    icon: "doc.text",
                    label: "Filename",
                    value: item.filename
                )
                
                // Performance metrics (if available)
                if let loadTime = item.loadTime {
                    // Load time in milliseconds
                    DetailRow(
                        icon: "clock.fill",
                        label: "Load Time",
                        value: String(format: "%.2f ms", loadTime * 1000)
                    )
                    
                    // Cache source indicator
                    DetailRow(
                        icon: item.fromCache ? "checkmark.circle.fill" : "arrow.down.circle.fill",
                        label: "Source",
                        value: item.fromCache ? "Cache Hit" : "Network"
                    )
                }
                
                // Image dimensions (platform-specific)
                if let image = item.image {
                    #if canImport(UIKit)
                    DetailRow(
                        icon: "photo",
                        label: "Dimensions",
                        value: "\(Int(image.size.width)) × \(Int(image.size.height))"
                    )
                    #elseif canImport(AppKit)
                    DetailRow(
                        icon: "photo",
                        label: "Dimensions",
                        value: "\(Int(image.size.width)) × \(Int(image.size.height))"
                    )
                    #endif
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)  // Glassmorphic background
            )
        }
        .padding(.horizontal)
    }
}

// MARK: - Detail Row

/// A single row displaying an icon, label, and value
///
/// Used in the metadata section to show key-value pairs like:
/// - Filename: "sample_1.jpg"
/// - Load Time: "2.45 ms"
/// - Dimensions: "1920 × 1080"
///
/// Layout:
/// - Icon (blue, fixed width) on left
/// - Label (secondary color) in center
/// - Value (bold) on right
struct DetailRow: View {
    // MARK: - Properties
    
    /// SF Symbol name for the icon
    let icon: String
    
    /// The label text (e.g., "Filename", "Load Time")
    let label: String
    
    /// The value to display (e.g., "sample_1.jpg", "2.45 ms")
    let value: String
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            // Icon with fixed width for alignment
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            // Label
            Text(label)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            // Value (bold for emphasis)
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}
