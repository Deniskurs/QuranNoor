//
//  UIScreen+Current.swift
//  QuranNoor
//
//  UIScreen.main replacement for iOS 26+ compatibility
//  Uses window scene context as recommended by Apple
//

import UIKit

extension UIWindow {
    /// Get the current key window from connected scenes
    /// Replaces deprecated UIApplication.keyWindow
    static var current: UIWindow? {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                if window.isKeyWindow { return window }
            }
        }
        return nil
    }
}

extension UIScreen {
    /// Get the current screen from the active window scene
    /// Replaces deprecated UIScreen.main for iOS 26+
    ///
    /// Usage:
    /// ```swift
    /// let screenBounds = UIScreen.current?.bounds ?? .zero
    /// let screenWidth = UIScreen.current?.bounds.width ?? 0
    /// ```
    static var current: UIScreen? {
        UIWindow.current?.screen
    }
}
