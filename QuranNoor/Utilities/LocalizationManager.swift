//
//  LocalizationManager.swift
//  QuranNoor
//
//  Comprehensive localization manager for multi-language support
//  Supports English, Arabic (RTL), and Urdu (RTL)
//

import SwiftUI
import Foundation
import Combine

// MARK: - Supported Languages

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case arabic = "ar"
    case urdu = "ur"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .arabic: return "العربية"
        case .urdu: return "اردو"
        }
    }

    var nativeName: String {
        switch self {
        case .english: return "English"
        case .arabic: return "العربية"
        case .urdu: return "اردو"
        }
    }

    var isRTL: Bool {
        switch self {
        case .arabic, .urdu:
            return true
        case .english:
            return false
        }
    }

    var layoutDirection: LayoutDirection {
        isRTL ? .rightToLeft : .leftToRight
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }
}

// MARK: - Localization Manager

@MainActor
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
            updateLayoutDirection()
        }
    }

    @Published var layoutDirection: LayoutDirection

    private init() {
        // Load saved language or use device language
        let savedLanguage: AppLanguage
        if let savedLang = UserDefaults.standard.string(forKey: "app_language"),
           let language = AppLanguage(rawValue: savedLang) {
            savedLanguage = language
        } else {
            // Detect device language
            let deviceLang = Locale.current.language.languageCode?.identifier ?? "en"
            savedLanguage = AppLanguage(rawValue: deviceLang) ?? .english
        }

        self.currentLanguage = savedLanguage
        self.layoutDirection = savedLanguage.layoutDirection
    }

    private func updateLayoutDirection() {
        layoutDirection = currentLanguage.layoutDirection
    }

    /// Change app language
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }

    /// Get localized string for key
    func string(for key: LocalizedKey) -> String {
        // In a real implementation, load from localization files
        // For now, return hardcoded strings based on current language
        return key.localized(for: currentLanguage)
    }
}

// MARK: - Localized Keys

enum LocalizedKey {
    // Onboarding
    case onboardingWelcomeTitle
    case onboardingWelcomeSubtitle
    case onboardingFeaturesTitle
    case onboardingLocationTitle
    case onboardingLocationSubtitle
    case onboardingNotificationTitle
    case onboardingNotificationSubtitle
    case onboardingThemeTitle
    case onboardingComplete

    // Buttons
    case buttonContinue
    case buttonSkip
    case buttonBack
    case buttonGetStarted
    case buttonEnable
    case buttonMaybeLater
    case buttonOpenSettings

    // Permissions
    case locationPermissionTitle
    case locationPermissionDescription
    case locationPermissionBenefit1
    case locationPermissionBenefit2
    case locationPermissionBenefit3
    case locationPrivacyAssurance

    case notificationPermissionTitle
    case notificationPermissionDescription
    case notificationPermissionBenefit1
    case notificationPermissionBenefit2
    case notificationPermissionBenefit3
    case notificationPermissionBenefit4

    // Features
    case featureQuranTitle
    case featureQuranSubtitle
    case featurePrayerTitle
    case featurePrayerSubtitle
    case featureQiblaTitle
    case featureQiblaSubtitle

    // General
    case appName
    case step(Int, Int)  // step X of Y

    func localized(for language: AppLanguage) -> String {
        switch language {
        case .english:
            return englishTranslation
        case .arabic:
            return arabicTranslation
        case .urdu:
            return urduTranslation
        }
    }

    // MARK: - English Translations

    private var englishTranslation: String {
        switch self {
        // Onboarding
        case .onboardingWelcomeTitle:
            return "Welcome to Qur'an Noor"
        case .onboardingWelcomeSubtitle:
            return "Your companion for prayer, Quran, and spiritual growth"
        case .onboardingFeaturesTitle:
            return "Discover Your Features"
        case .onboardingLocationTitle:
            return "Prayer Times Setup"
        case .onboardingLocationSubtitle:
            return "Get accurate prayer times for your location"
        case .onboardingNotificationTitle:
            return "Prayer Reminders"
        case .onboardingNotificationSubtitle:
            return "Never miss a prayer with timely notifications"
        case .onboardingThemeTitle:
            return "Choose Your Theme"
        case .onboardingComplete:
            return "You're All Set!"

        // Buttons
        case .buttonContinue:
            return "Continue"
        case .buttonSkip:
            return "Skip"
        case .buttonBack:
            return "Back"
        case .buttonGetStarted:
            return "Get Started"
        case .buttonEnable:
            return "Enable"
        case .buttonMaybeLater:
            return "Maybe Later"
        case .buttonOpenSettings:
            return "Open Settings"

        // Permissions
        case .locationPermissionTitle:
            return "See Your Exact Prayer Times"
        case .locationPermissionDescription:
            return "We use your location once to calculate accurate prayer times for your area"
        case .locationPermissionBenefit1:
            return "Precise prayer times based on your exact location"
        case .locationPermissionBenefit2:
            return "Accurate Qibla direction to Mecca"
        case .locationPermissionBenefit3:
            return "Location-aware prayer notifications"
        case .locationPrivacyAssurance:
            return "Your location stays on your device and is never shared or tracked"

        case .notificationPermissionTitle:
            return "Never Miss a Prayer"
        case .notificationPermissionDescription:
            return "Get gentle reminders before each prayer time"
        case .notificationPermissionBenefit1:
            return "Timely reminders for all 5 daily prayers"
        case .notificationPermissionBenefit2:
            return "Beautiful Adhan call to prayer (optional)"
        case .notificationPermissionBenefit3:
            return "Fully customizable notification settings"
        case .notificationPermissionBenefit4:
            return "Special reminders for Tahajjud and Witr"

        // Features
        case .featureQuranTitle:
            return "Beautiful Quran Reader"
        case .featureQuranSubtitle:
            return "Read, listen, and understand with translations and audio"
        case .featurePrayerTitle:
            return "Never Miss a Prayer"
        case .featurePrayerSubtitle:
            return "Accurate prayer times with smart notifications"
        case .featureQiblaTitle:
            return "Find Qibla Anywhere"
        case .featureQiblaSubtitle:
            return "Precise direction to Makkah using your device"

        // General
        case .appName:
            return "Qur'an Noor"
        case .step(let current, let total):
            return "Step \(current) of \(total)"
        }
    }

    // MARK: - Arabic Translations

    private var arabicTranslation: String {
        switch self {
        // Onboarding
        case .onboardingWelcomeTitle:
            return "مرحبا بك في قرآن نور"
        case .onboardingWelcomeSubtitle:
            return "رفيقك للصلاة والقرآن والنمو الروحي"
        case .onboardingFeaturesTitle:
            return "اكتشف الميزات"
        case .onboardingLocationTitle:
            return "إعداد أوقات الصلاة"
        case .onboardingLocationSubtitle:
            return "احصل على أوقات صلاة دقيقة لموقعك"
        case .onboardingNotificationTitle:
            return "تذكيرات الصلاة"
        case .onboardingNotificationSubtitle:
            return "لا تفوت صلاة مع الإشعارات في الوقت المناسب"
        case .onboardingThemeTitle:
            return "اختر المظهر الخاص بك"
        case .onboardingComplete:
            return "كل شيء جاهز!"

        // Buttons
        case .buttonContinue:
            return "متابعة"
        case .buttonSkip:
            return "تخطي"
        case .buttonBack:
            return "رجوع"
        case .buttonGetStarted:
            return "ابدأ"
        case .buttonEnable:
            return "تمكين"
        case .buttonMaybeLater:
            return "ربما لاحقا"
        case .buttonOpenSettings:
            return "فتح الإعدادات"

        // Permissions
        case .locationPermissionTitle:
            return "شاهد أوقات صلاتك الدقيقة"
        case .locationPermissionDescription:
            return "نستخدم موقعك مرة واحدة لحساب أوقات الصلاة الدقيقة لمنطقتك"
        case .locationPermissionBenefit1:
            return "أوقات صلاة دقيقة بناءً على موقعك الدقيق"
        case .locationPermissionBenefit2:
            return "اتجاه القبلة الدقيق إلى مكة"
        case .locationPermissionBenefit3:
            return "إشعارات الصلاة بناءً على الموقع"
        case .locationPrivacyAssurance:
            return "يبقى موقعك على جهازك ولا تتم مشاركته أو تتبعه أبدًا"

        case .notificationPermissionTitle:
            return "لا تفوت صلاة"
        case .notificationPermissionDescription:
            return "احصل على تذكيرات لطيفة قبل كل وقت صلاة"
        case .notificationPermissionBenefit1:
            return "تذكيرات في الوقت المناسب لجميع الصلوات الخمس اليومية"
        case .notificationPermissionBenefit2:
            return "أذان جميل للصلاة (اختياري)"
        case .notificationPermissionBenefit3:
            return "إعدادات إشعارات قابلة للتخصيص بالكامل"
        case .notificationPermissionBenefit4:
            return "تذكيرات خاصة للتهجد والوتر"

        // Features
        case .featureQuranTitle:
            return "قارئ قرآن جميل"
        case .featureQuranSubtitle:
            return "اقرأ واستمع وافهم مع الترجمات والصوت"
        case .featurePrayerTitle:
            return "لا تفوت صلاة"
        case .featurePrayerSubtitle:
            return "أوقات صلاة دقيقة مع إشعارات ذكية"
        case .featureQiblaTitle:
            return "اعثر على القبلة في أي مكان"
        case .featureQiblaSubtitle:
            return "اتجاه دقيق إلى مكة باستخدام جهازك"

        // General
        case .appName:
            return "قرآن نور"
        case .step(let current, let total):
            return "الخطوة \(current) من \(total)"
        }
    }

    // MARK: - Urdu Translations

    private var urduTranslation: String {
        switch self {
        // Onboarding
        case .onboardingWelcomeTitle:
            return "قرآن نور میں خوش آمدید"
        case .onboardingWelcomeSubtitle:
            return "نماز، قرآن اور روحانی ترقی کے لیے آپ کا ساتھی"
        case .onboardingFeaturesTitle:
            return "اپنی خصوصیات دریافت کریں"
        case .onboardingLocationTitle:
            return "نماز کے اوقات کی تشکیل"
        case .onboardingLocationSubtitle:
            return "اپنے مقام کے لیے درست نماز کے اوقات حاصل کریں"
        case .onboardingNotificationTitle:
            return "نماز کی یاد دہانیاں"
        case .onboardingNotificationSubtitle:
            return "بروقت اطلاعات کے ساتھ کوئی نماز نہ چھوٹے"
        case .onboardingThemeTitle:
            return "اپنی تھیم منتخب کریں"
        case .onboardingComplete:
            return "آپ تیار ہیں!"

        // Buttons
        case .buttonContinue:
            return "جاری رکھیں"
        case .buttonSkip:
            return "چھوڑیں"
        case .buttonBack:
            return "واپس"
        case .buttonGetStarted:
            return "شروع کریں"
        case .buttonEnable:
            return "فعال کریں"
        case .buttonMaybeLater:
            return "شاید بعد میں"
        case .buttonOpenSettings:
            return "ترتیبات کھولیں"

        // Permissions
        case .locationPermissionTitle:
            return "اپنے صحیح نماز کے اوقات دیکھیں"
        case .locationPermissionDescription:
            return "ہم آپ کے علاقے کے لیے درست نماز کے اوقات کا حساب لگانے کے لیے ایک بار آپ کے مقام کا استعمال کرتے ہیں"
        case .locationPermissionBenefit1:
            return "آپ کے صحیح مقام پر مبنی درست نماز کے اوقات"
        case .locationPermissionBenefit2:
            return "مکہ کی طرف درست قبلہ کی سمت"
        case .locationPermissionBenefit3:
            return "مقام سے آگاہ نماز کی اطلاعات"
        case .locationPrivacyAssurance:
            return "آپ کا مقام آپ کے آلے پر رہتا ہے اور کبھی شیئر یا ٹریک نہیں کیا جاتا"

        case .notificationPermissionTitle:
            return "کوئی نماز نہ چھوٹے"
        case .notificationPermissionDescription:
            return "ہر نماز کے وقت سے پہلے نرم یاد دہانیاں حاصل کریں"
        case .notificationPermissionBenefit1:
            return "تمام 5 روزانہ نمازوں کے لیے بروقت یاد دہانیاں"
        case .notificationPermissionBenefit2:
            return "خوبصورت اذان (اختیاری)"
        case .notificationPermissionBenefit3:
            return "مکمل طور پر حسب ضرورت اطلاعات کی ترتیبات"
        case .notificationPermissionBenefit4:
            return "تہجد اور وتر کے لیے خصوصی یاد دہانیاں"

        // Features
        case .featureQuranTitle:
            return "خوبصورت قرآن ریڈر"
        case .featureQuranSubtitle:
            return "تراجم اور آڈیو کے ساتھ پڑھیں، سنیں اور سمجھیں"
        case .featurePrayerTitle:
            return "کوئی نماز نہ چھوٹے"
        case .featurePrayerSubtitle:
            return "سمارٹ اطلاعات کے ساتھ درست نماز کے اوقات"
        case .featureQiblaTitle:
            return "کہیں بھی قبلہ تلاش کریں"
        case .featureQiblaSubtitle:
            return "اپنے آلے کا استعمال کرتے ہوئے مکہ کی طرف درست سمت"

        // General
        case .appName:
            return "قرآن نور"
        case .step(let current, let total):
            return "قدم \(current) از \(total)"
        }
    }
}

// MARK: - View Extensions for Localization

extension View {
    func localized(_ key: LocalizedKey) -> String {
        LocalizationManager.shared.string(for: key)
    }

    /// Apply RTL layout if needed
    func adaptiveLayout() -> some View {
        self.environment(\.layoutDirection, LocalizationManager.shared.layoutDirection)
    }
}

// MARK: - String Extension

extension String {
    func localized() -> String {
        // For static strings, use Bundle localization
        NSLocalizedString(self, comment: "")
    }
}
