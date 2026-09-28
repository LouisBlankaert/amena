import Foundation

func t(_ en: String, _ fr: String) -> String {
    UserDefaults.standard.string(forKey: "prayerLanguage") == "French" ? fr : en
}

// Langue des dates : celle choisie dans l'app, pas celle du téléphone
// (un iPhone en anglais avec l'app en français doit afficher "lundi 28 septembre")
var appLocale: Locale {
    Locale(identifier: t("en_US", "fr_FR"))
}

extension String {
    // "lundi 28 septembre" → "Lundi 28 septembre" (.capitalized mettrait "Septembre")
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
