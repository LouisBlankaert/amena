import Foundation

func t(_ en: String, _ fr: String) -> String {
    UserDefaults.standard.string(forKey: "prayerLanguage") == "French" ? fr : en
}
