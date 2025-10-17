//
//  ActivityViewController.swift
//  Numpad
//
//  Created on 2025-10-16.
//

import SwiftUI
import UIKit

/// UIViewControllerRepresentable wrapper for UIActivityViewController (iOS share sheet)
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
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
