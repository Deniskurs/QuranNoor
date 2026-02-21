//
//  AirPlayButton.swift
//  QuranNoor
//
//  UIViewRepresentable wrapping AVRoutePickerView for AirPlay output selection.
//

import SwiftUI
import AVKit

struct AirPlayButton: UIViewRepresentable {
    let tintColor: Color

    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.activeTintColor = UIColor(tintColor)
        picker.tintColor = UIColor(tintColor)
        picker.prioritizesVideoDevices = false
        return picker
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        uiView.activeTintColor = UIColor(tintColor)
        uiView.tintColor = UIColor(tintColor)
    }
}
