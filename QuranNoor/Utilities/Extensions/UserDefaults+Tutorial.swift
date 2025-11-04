//
//  UserDefaults+Tutorial.swift
//  QuranNoor
//
//  Helper extension for managing tutorial preferences
//

import Foundation

extension UserDefaults {
    /// Reset the Qibla tutorial so it will be shown again
    /// Useful for testing and development
    static func resetQiblaTutorial() {
        standard.removeObject(forKey: "hasSeenQiblaTutorial")
    }

    /// Check if the Qibla tutorial has been seen
    static var hasSeenQiblaTutorial: Bool {
        get {
            standard.bool(forKey: "hasSeenQiblaTutorial")
        }
        set {
            standard.set(newValue, forKey: "hasSeenQiblaTutorial")
        }
    }
}
