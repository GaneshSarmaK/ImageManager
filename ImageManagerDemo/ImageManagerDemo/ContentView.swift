//
//  ContentView.swift
//  ImageManagerDemo
//
//  Created by NVR4GET on 13/12/2025.
//

import SwiftUI
import ImageManager

/// Main view of the ImageManager demo application
///
/// This view demonstrates the capabilities of the ImageManager package by providing
/// an interactive interface for testing:
/// - Image downloading and caching from Unsplash
/// - Image transformation (crop, resize, compress)
/// - Cache performance comparison (network vs cache)
/// - Cache management and statistics
///
/// Layout structure (top to bottom):
/// 1. **Header** - App title and description
/// 2. **Cache Statistics** - 3 stat cards showing metrics
/// 3. **Demo Actions** - 4 buttons for different operations
/// 4. **Image Grid** - 2-column grid of loaded images
/// 5. **Error Banner** - Shown when operations fail
///
/// The view uses a `ManagerViewModel` to manage business logic and state.
struct ContentView: View {
    // MARK: - State
    
    /// ViewModel managing all business logic and state
    @State private var viewModel = ManagerViewModel()
    
    /// Currently selected image item for detail sheet presentation
    @State var imageItem: ImageItem?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // App header with title and description
                    headerSection
                    
                    // Cache statistics dashboard
                    cacheStatsSection
                    
                    // Action buttons for demo operations
                    actionsSection
                    
                    // Grid of loaded/transformed images
                    imageGridSection
                }
                .padding()
            }
            .navigationTitle("ImageManager Demo")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $imageItem) { item in
                // Present detail view when image is tapped
                ImageDetailView(item: item)
            }
        }
    }
    
    // MARK: - Header Section
    
    /// App header with icon, title, and description
    ///
    /// Features:
    /// - Large photo stack icon with gradient
    /// - App title and subtitle
    /// - Centered layout
    private var headerSection: some View {
        VStack(spacing: 12) {
            // App icon with gradient styling
            Image(systemName: "photo.stack.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // App title
            Text("Image Caching & Transformation")
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            // Description
            Text("Test ImageManager's caching, loading, and transformation capabilities")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // MARK: - Cache Stats Section
    
    /// Dashboard displaying cache performance statistics
    ///
    /// Shows three key metrics:
    /// 1. **Images** - Number of cached images
    /// 2. **Cache Size** - Total disk space used (formatted)
    /// 3. **Load Time** - Last operation duration in milliseconds
    ///
    /// Each stat is displayed in a color-coded `StatCard` component.
    private var cacheStatsSection: some View {
        VStack(spacing: 16) {
            // Section title
            Text("Cache Statistics")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Three stat cards in a horizontal row
            HStack(spacing: 12) {
                // Number of cached images (blue)
                StatCard(
                    title: "Images",
                    value: "\(viewModel.cachedImagesCount)",
                    icon: "photo.on.rectangle.angled",
                    color: .blue
                )
                
                // Total cache size (purple)
                StatCard(
                    title: "Cache Size",
                    value: viewModel.cacheSizeFormatted,
                    icon: "externaldrive.fill",
                    color: .purple
                )
                
                // Last operation load time (green)
                StatCard(
                    title: "Load Time",
                    value: viewModel.lastLoadTimeFormatted,
                    icon: "clock.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)  // Glassmorphic background
        )
    }
    
    // MARK: - Actions Section
    
    /// Action buttons for testing different ImageManager features
    ///
    /// Four main actions:
    /// 1. **Load Sample Images** - Download 6 images from Unsplash
    /// 2. **Test Transformations** - Apply crops/resizes to first 3 images
    /// 3. **Reload from Cache** - Reload all images to measure cache performance
    /// 4. **Clear Cache** - Remove all cached images and reset stats
    ///
    /// Each button shows a loading indicator during async operations.
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Section title
            Text("Demo Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Stack of action buttons
            VStack(spacing: 10) {
                // Download sample images from Unsplash
                ActionButton(
                    title: "Load Sample Images",
                    icon: "arrow.down.circle.fill",
                    color: .blue,
                    isLoading: viewModel.isLoading
                ) {
                    Task {
                        await viewModel.loadSampleImages()
                    }
                }
                
                // Apply transformations to first 3 images
                ActionButton(
                    title: "Test Transformations",
                    icon: "wand.and.stars",
                    color: .purple,
                    isLoading: viewModel.isTransforming
                ) {
                    Task {
                        await viewModel.testTransformations()
                    }
                }
                
                // Reload all images from cache to measure performance
                ActionButton(
                    title: "Reload from Cache",
                    icon: "arrow.clockwise.circle.fill",
                    color: .green
                ) {
                    Task {
                        await viewModel.reloadFromCache()
                    }
                }
                
                // Clear all cached images and reset
                ActionButton(
                    title: "Clear Cache",
                    icon: "trash.circle.fill",
                    color: .red
                ) {
                    viewModel.clearCache()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Image Grid Section
    
    /// Grid displaying all loaded and transformed images
    ///
    /// Layout:
    /// - 2-column grid with flexible column widths
    /// - Each image is an `ImageCard` component
    /// - Tapping an image presents `ImageDetailView` as a sheet
    ///
    /// Also displays an error banner if any operation fails.
    private var imageGridSection: some View {
        VStack(spacing: 16) {
            // Only show grid if images are loaded
            if !viewModel.images.isEmpty {
                // Section title
                Text("Loaded Images")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // 2-column grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(viewModel.images) { imageItem in
                        ImageCard(item: imageItem, frameHeight: 150)
                            .onTapGesture {
                                // Present detail sheet on tap
                                self.imageItem = imageItem
                            }
                    }
                }
            }
            
            // Show error banner if present
            if viewModel.errorMessage != nil {
                ErrorBanner(message: viewModel.errorMessage!)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
