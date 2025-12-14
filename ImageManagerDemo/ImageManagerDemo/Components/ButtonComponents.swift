//
//  ButtonComponents.swift
//  ImageManagerDemo
//
//  Created by NVR4GET on 13/12/2025.
//

import SwiftUI

// MARK: - Action Button

/// A full-width gradient button with loading state support
///
/// Features:
/// - Gradient background using provided color
/// - Icon + text layout
/// - Loading state with ProgressView
/// - Disabled state during loading
/// - Rounded corners for modern appearance
///
/// Usage:
/// ```swift
/// ActionButton(
///     title: "Load Images",
///     icon: "arrow.down.circle.fill",
///     color: .blue,
///     isLoading: viewModel.isLoading
/// ) {
///     Task { await viewModel.loadImages() }
/// }
/// ```
struct ActionButton: View {
    // MARK: - Properties
    
    /// Button label text
    let title: String
    
    /// SF Symbol name for the icon
    let icon: String
    
    /// Color for the gradient background
    let color: Color
    
    /// Whether the button is in loading state
    /// - When true, shows ProgressView and disables interaction
    var isLoading: Bool = false
    
    /// Action to perform when button is tapped
    let action: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Show either loading indicator or icon
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: icon)
                }
                
                // Button label
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)  // Full width
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.gradient)  // Gradient fill
            )
            .foregroundStyle(.white)  // White text and icons
        }
        .disabled(isLoading)  // Prevent multiple taps during loading
    }
}

// MARK: - Error Banner

/// A banner for displaying error messages to the user
///
/// Features:
/// - Red gradient background for visibility
/// - Warning icon (exclamation triangle)
/// - Full-width layout
/// - Rounded corners
///
/// Usage:
/// ```swift
/// if let error = viewModel.errorMessage {
///     ErrorBanner(message: error)
/// }
/// ```
struct ErrorBanner: View {
    // MARK: - Properties
    
    /// The error message to display
    let message: String
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            // Warning icon
            Image(systemName: "exclamationmark.triangle.fill")
            
            // Error message
            Text(message)
                .font(.subheadline)
        }
        .foregroundStyle(.white)
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.red.gradient)  // Red gradient for errors
        )
    }
}
