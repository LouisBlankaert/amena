// Carnet : les intentions de prière de l'utilisateur, celles qui ont été exaucées,
// et les prières passées. C'est l'écran qui donne une raison de revenir : on y
// écrit pour qui on prie, et on y voit, semaine après semaine, ce qui a été exaucé.

import SwiftUI

struct JournalView: View {
    @State private var prayers: [PrayerEntry] = []
    @State private var requests: [PrayerRequest] = []
    @State private var newRequest = ""
    @State private var displayedCount = 10
    @State private var readingPrayer: PrayerEntry?
    @FocusState private var isWriting: Bool
    @AppStorage("prayerLanguage") private var lang: String = "English"

    private var active: [PrayerRequest] { requests.filter { !$0.isAnswered } }
    private var answered: [PrayerRequest] {
        requests.filter(\.isAnswered).sorted { ($0.answeredAt ?? .distantPast) > ($1.answeredAt ?? .distantPast) }
    }
    private var visiblePrayers: [PrayerEntry] { Array(prayers.prefix(displayedCount)) }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                SkyMoment.current.colors.first!.frame(height: 300)
                Color.amenaBackground
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    header

                    VStack(alignment: .leading, spacing: 32) {
                        requestsSection
                        if !answered.isEmpty { answeredSection }
                        prayersSection
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .background(Color.amenaBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .padding(.top, -32)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear(perform: load)
        .sheet(item: $readingPrayer) { prayer in
            PrayerReadingView(prayer: prayer)
        }
    }

    // MARK: - En-tête sous le ciel

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(t("Notebook", "Carnet"))
                .font(.system(size: 34, weight: .regular, design: .serif))
                .foregroundColor(.white)
            Text(answered.isEmpty
                 ? t("Write down who you pray for. Mark it answered when it happens.",
                     "Écrivez pour qui vous priez. Marquez-le exaucé quand ça arrive.")
                 : t("\(answered.count) answered \(answered.count > 1 ? "prayers" : "prayer"). Keep going.",
                     "\(answered.count) \(answered.count > 1 ? "prières exaucées" : "prière exaucée"). Continuez."))
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 64)
        .background(SkyBackground(moment: SkyMoment.current).ignoresSafeArea(edges: .top))
    }

    // MARK: - Intentions en cours

    private var requestsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(t("I'm praying for", "Je prie pour"))

            HStack(spacing: 10) {
                TextField(t("Sarah's exam, my father's health…", "L'examen de Sarah, la santé de papa…"), text: $newRequest)
                    .font(.system(size: 17, design: .serif))
                    .focused($isWriting)
                    .submitLabel(.done)
                    .onSubmit(addRequest)
                Button(action: addRequest) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(canAdd ? Color.amenaNightBlue : Color.amenaTextSecondary.opacity(0.4))
                        .clipShape(Circle())
                }
                .disabled(!canAdd)
                .accessibilityLabel(t("Add", "Ajouter"))
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .padding(.vertical, 8)
            .background(Color.amenaSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            if active.isEmpty {
                Text(t("Your daily prayer will name them, until they're answered.",
                       "Votre prière du jour les nommera, jusqu'à ce qu'elles soient exaucées."))
                    .font(.system(size: 14))
                    .foregroundColor(Color.amenaTextSecondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(active) { request in
                        RequestRow(request: request, onAnswered: { markAnswered(request) })
                            .contextMenu {
                                Button(role: .destructive) { delete(request) } label: {
                                    Label(t("Delete", "Supprimer"), systemImage: "trash")
                                }
                            }
                        if request.id != active.last?.id { Divider() }
                    }
                }
            }
        }
    }

    // MARK: - Exaucées

    private var answeredSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(t("Answered", "Exaucées"))
            VStack(spacing: 0) {
                ForEach(answered) { request in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(Color.amenaGold)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(request.text)
                                .font(.system(size: 17, design: .serif))
                                .foregroundColor(Color.amenaText)
                            Text(answeredCaption(request))
                                .font(.system(size: 13))
                                .foregroundColor(Color.amenaTextSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 12)
                    .contextMenu {
                        Button { reopen(request) } label: {
                            Label(t("Not answered yet", "Pas encore exaucée"), systemImage: "arrow.uturn.backward")
                        }
                        Button(role: .destructive) { delete(request) } label: {
                            Label(t("Delete", "Supprimer"), systemImage: "trash")
                        }
                    }
                    if request.id != answered.last?.id { Divider() }
                }
            }
        }
    }

    // MARK: - Prières passées

    private var prayersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(t("Your prayers", "Vos prières"))
            if prayers.isEmpty {
                Text(t("Your prayers will be kept here, to read again whenever you want.",
                       "Vos prières seront gardées ici, pour les relire quand vous voulez."))
                    .font(.system(size: 14))
                    .foregroundColor(Color.amenaTextSecondary)
            } else {
                ForEach(visiblePrayers) { prayer in
                    Button { readingPrayer = prayer } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(prayer.date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(appLocale)).capitalizedFirst)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.amenaTextSecondary)
                            Text(prayer.preview)
                                .font(.system(size: 16, design: .serif))
                                .foregroundColor(Color.amenaText)
                                .multilineTextAlignment(.leading)
                                .lineSpacing(3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.amenaSecondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                if displayedCount < prayers.count {
                    Button(t("Show more", "Voir plus")) {
                        displayedCount = min(displayedCount + 10, prayers.count)
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.amenaNightBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
    }

    // MARK: - Actions

    private var canAdd: Bool { !newRequest.trimmingCharacters(in: .whitespaces).isEmpty }

    private func addRequest() {
        let text = newRequest.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        withAnimation { requests.insert(PrayerRequest(text: text), at: 0) }
        PrayerRequestStore.save(requests)
        newRequest = ""
        isWriting = false
    }

    private func markAnswered(_ request: PrayerRequest) {
        guard let i = requests.firstIndex(where: { $0.id == request.id }) else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.easeInOut(duration: 0.35)) { requests[i].answeredAt = Date() }
        PrayerRequestStore.save(requests)
    }

    private func reopen(_ request: PrayerRequest) {
        guard let i = requests.firstIndex(where: { $0.id == request.id }) else { return }
        withAnimation { requests[i].answeredAt = nil }
        PrayerRequestStore.save(requests)
    }

    private func delete(_ request: PrayerRequest) {
        withAnimation { requests.removeAll { $0.id == request.id } }
        PrayerRequestStore.save(requests)
    }

    private func answeredCaption(_ request: PrayerRequest) -> String {
        let date = (request.answeredAt ?? Date()).formatted(.dateTime.day().month(.wide).locale(appLocale))
        let days = request.daysPrayed
        return t("Answered on \(date), after \(days) \(days > 1 ? "days" : "day") of prayer",
                 "Exaucée le \(date), après \(days) \(days > 1 ? "jours" : "jour") de prière")
    }

    private func load() {
        requests = PrayerRequestStore.load()
        if let data = UserDefaults.standard.data(forKey: "prayerJournal"),
           let decoded = try? JSONDecoder().decode([PrayerEntry].self, from: data) {
            // Limite à 90 entrées max — supprime les plus anciennes
            prayers = Array(decoded.prefix(90))
            if decoded.count > 90, let encoded = try? JSONEncoder().encode(prayers) {
                UserDefaults.standard.set(encoded, forKey: "prayerJournal")
            }
        }
    }
}

// Titre de section du Carnet
private struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 22, weight: .regular, design: .serif))
            .foregroundColor(Color.amenaText)
    }
}

// Une intention en cours, avec le bouton pour la marquer exaucée
private struct RequestRow: View {
    let request: PrayerRequest
    let onAnswered: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(request.text)
                    .font(.system(size: 17, design: .serif))
                    .foregroundColor(Color.amenaText)
                Text(t("Praying for \(request.daysPrayed) \(request.daysPrayed > 1 ? "days" : "day")",
                       "Vous priez depuis \(request.daysPrayed) \(request.daysPrayed > 1 ? "jours" : "jour")"))
                    .font(.system(size: 13))
                    .foregroundColor(Color.amenaTextSecondary)
            }
            Spacer(minLength: 0)
            Button(action: onAnswered) {
                Text(t("Answered", "Exaucée"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.amenaNightBlue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .overlay(Capsule().stroke(Color.amenaNightBlue.opacity(0.3), lineWidth: 1))
            }
            .accessibilityHint(t("Moves this intention to your answered prayers", "Range cette intention dans vos prières exaucées"))
        }
        .padding(.vertical, 12)
    }
}

// Relire une prière passée, en plein texte, sous le ciel
private struct PrayerReadingView: View {
    let prayer: PrayerEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            SkyBackground(moment: SkyMoment.current).ignoresSafeArea()
            Color.black.opacity(0.35).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(prayer.date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(appLocale)).capitalizedFirst)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 40, height: 40)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel(t("Close", "Fermer"))
                    }
                    Text(prayer.text)
                        .font(.system(size: 19, design: .serif))
                        .foregroundColor(.white)
                        .lineSpacing(9)
                    ShareLink(item: prayer.text) {
                        Label(t("Share this prayer", "Partager cette prière"), systemImage: "square.and.arrow.up")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.top, 8)
                }
                .padding(24)
            }
        }
    }
}

// Modèle d'une entrée de prière dans le journal
struct PrayerEntry: Identifiable, Codable {
    let id: UUID
    let text: String
    let date: Date

    // Extrait les premiers mots comme résumé
    var preview: String {
        let words = text.split(separator: " ").prefix(15)
        return words.joined(separator: " ") + (text.split(separator: " ").count > 15 ? "…" : "")
    }
}

#Preview {
    JournalView()
}
