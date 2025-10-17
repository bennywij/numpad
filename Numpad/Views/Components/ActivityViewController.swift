//
//  ActivityViewController.swift
//  Numpad
//
//  Created on 2025-10-16.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// UIViewControllerRepresentable wrapper for UIActivityViewController (iOS share sheet)
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Convert URLs to NSItemProvider for better metadata handling
        let providers = activityItems.map { item -> Any in
            if let url = item as? URL {
                // Use NSItemProvider to avoid LaunchServices errors
                let provider = NSItemProvider(contentsOf: url)
                provider?.suggestedName = url.lastPathComponent
                return provider ?? url
            }
            return item
        }

        let controller = UIActivityViewController(
            activityItems: providers,
            applicationActivities: nil
        )

        // Exclude activities that might not work well with temporary files
        controller.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact
        ]

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

/// Helper struct to make URL identifiable for sheet presentation
struct ExportFile: Identifiable {
    let id = UUID()
    let url: URL
}
