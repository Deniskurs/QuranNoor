//
//  ShareSheet.swift
//  QuranNoor
//
//  UIKit bridge for native iOS share sheet
//  Used throughout the app for sharing content
//

import SwiftUI
import UIKit

/// UIKit bridge to present native iOS share sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
