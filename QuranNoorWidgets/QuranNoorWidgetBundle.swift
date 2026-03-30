//
//  QuranNoorWidgetBundle.swift
//  QuranNoorWidgets
//
//  Widget extension entry point — registers all widgets
//

import SwiftUI
import WidgetKit

@main
struct QuranNoorWidgetBundle: WidgetBundle {
    var body: some Widget {
        PrayerTimesWidget()
        QuranProgressWidget()
    }
}
