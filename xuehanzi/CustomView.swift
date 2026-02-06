import SwiftUI
import SwiftData
import UniformTypeIdentifiers

private struct ParsedCard {
    let front: String
    let back: String
    let subdeck: String
}

struct CustomView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomDeck.createdDate, order: .reverse) private var decks: [CustomDeck]

    @State private var showFilePicker = false
    @State private var showNamePrompt = false
    @State private var pendingCards: [ParsedCard] = []
    @State private var deckName = ""
    @State private var showImportError = false
    @State private var importErrorMessage = ""
    @State private var showMergePrompt = false
    @State private var existingDeckForMerge: CustomDeck? = nil
    @State private var showDeleteConfirm = false
    @State private var deckToDelete: CustomDeck? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                heroBanner

                VStack(spacing: 20) {
                    statsStrip
                        .padding(.top, -28)

                    importButton

                    if decks.isEmpty {
                        emptyState
                    } else {
                        decksSectionHeader

                        ForEach(decks) { deck in
                            CustomDeckCard(deck: deck, onDelete: {
                                deckToDelete = deck
                                showDeleteConfirm = true
                            })
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .background(Color(red: 0.96, green: 0.955, blue: 0.94).ignoresSafeArea())
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.plainText, .commaSeparatedText, .tabSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .alert("Name Your Deck", isPresented: $showNamePrompt) {
            TextField("Deck name", text: $deckName)
            Button("Create") {
                createDeck()
            }
            Button("Cancel", role: .cancel) {
                pendingCards = []
                deckName = ""
            }
        } message: {
            Text("\(pendingCards.count) cards found. Give your deck a name.")
        }
        .alert("Deck Already Exists", isPresented: $showMergePrompt) {
            Button("Merge New Cards") { mergeDeck() }
            Button("Cancel", role: .cancel) {
                pendingCards = []
                deckName = ""
                existingDeckForMerge = nil
            }
        } message: {
            Text("A deck named \"\(deckName)\" already exists. New cards will be added and existing progress will be kept.")
        }
        .alert("Delete Deck?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let deck = deckToDelete {
                    deleteDeck(deck)
                }
                deckToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                deckToDelete = nil
            }
        } message: {
            if let deck = deckToDelete {
                Text("This will permanently delete \"\(deck.name)\" and all \(deck.cards.count) cards.")
            } else {
                Text("This will permanently delete this deck.")
            }
        }
        .alert("Import Error", isPresented: $showImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importErrorMessage)
        }
    }

    // MARK: - Hero Banner
    private var heroBanner: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [
                    Color(red: 0.24, green: 0.58, blue: 0.78),
                    Color(red: 0.32, green: 0.68, blue: 0.86),
                    Color(red: 0.45, green: 0.78, blue: 0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 180, height: 180)
                .offset(x: 230, y: -30)

            Circle()
                .fill(.white.opacity(0.04))
                .frame(width: 120, height: 120)
                .offset(x: -20, y: 80)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("自定义")
                        .font(.system(size: 32, weight: .black, design: .serif))
                        .foregroundStyle(.white)

                    Text("Custom Decks")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.75))
                }

                if decks.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.subheadline)
                        Text("Import your first deck to get started")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(.white.opacity(0.9))
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "tray.full.fill")
                            .font(.subheadline)
                        Text("\(decks.count) \(decks.count == 1 ? "deck" : "decks") imported")
                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundStyle(.white.opacity(0.9))
                }

                Spacer().frame(height: 28)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .clipShape(
            UnevenRoundedRectangle(bottomLeadingRadius: 24, bottomTrailingRadius: 24)
        )
    }

    // MARK: - Stats Strip
    private var statsStrip: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(AppTheme.customTeal.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "tray.full.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.customTeal)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(decks.count)")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(decks.count == 1 ? "Deck" : "Decks")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            )

            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(AppTheme.info.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.info)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(totalCards)")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Cards")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            )

            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(AppTheme.success.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.success)
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(totalStudied)")
                        .font(.subheadline.weight(.black))
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Learned")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            )
        }
    }

    // MARK: - Import Button
    private var importButton: some View {
        Button {
            showFilePicker = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "square.and.arrow.down")
                    .font(.subheadline.weight(.semibold))
                Text("Import Deck")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(AppTheme.customTeal)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(AppTheme.customTeal.opacity(0.12))
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(BounceButtonStyle())
    }

    // MARK: - Section Header
    private var decksSectionHeader: some View {
        HStack {
            Text("Your Decks")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.primaryText)

            Spacer()

            Text("\(totalStudied) learned")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.top, 4)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 30)

            ZStack {
                Circle()
                    .fill(AppTheme.customTeal.opacity(0.10))
                    .frame(width: 100, height: 100)

                Image(systemName: "tray.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(AppTheme.customTeal)
            }

            VStack(spacing: 8) {
                Text("No Custom Decks")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)

                Text("Import an Anki text export (.txt) to create\na custom study deck.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            VStack(spacing: 4) {
                Text("Supported formats:")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryText)
                Text("Anki text exports, tab or comma separated files")
                    .font(.caption)
                    .foregroundStyle(AppTheme.tertiaryText)
            }

            Spacer().frame(height: 30)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Computed
    private var totalCards: Int {
        decks.reduce(0) { $0 + $1.cards.count }
    }

    private var totalStudied: Int {
        decks.reduce(0) { sum, deck in
            sum + deck.cards.filter { $0.repetitions >= 1 }.count
        }
    }

    // MARK: - File Import
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else {
                importErrorMessage = "Could not access the file."
                showImportError = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                let (cards, rootName) = parseAnkiFile(content)

                if cards.isEmpty {
                    importErrorMessage = "No valid cards found. Make sure the file has at least two columns (front and back)."
                    showImportError = true
                    return
                }

                pendingCards = cards
                deckName = rootName ?? url.deletingPathExtension().lastPathComponent
                showNamePrompt = true
            } catch {
                importErrorMessage = "Could not read the file: \(error.localizedDescription)"
                showImportError = true
            }

        case .failure(let error):
            importErrorMessage = "File picker error: \(error.localizedDescription)"
            showImportError = true
        }
    }

    // MARK: - Anki File Parser
    private func parseAnkiFile(_ content: String) -> (cards: [ParsedCard], rootDeckName: String?) {
        let lines = content.components(separatedBy: .newlines)

        // Parse metadata from # lines
        var separator = "\t"
        var deckColumnIndex: Int? = nil // 0-indexed
        var isHTML = false
        var dataLines: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") {
                let lower = trimmed.lowercased()
                if lower.hasPrefix("#separator:") {
                    let value = String(trimmed.dropFirst("#separator:".count)).trimmingCharacters(in: .whitespaces).lowercased()
                    switch value {
                    case "tab": separator = "\t"
                    case "comma": separator = ","
                    case "semicolon": separator = ";"
                    case "pipe": separator = "|"
                    default: separator = value
                    }
                } else if lower.hasPrefix("#html:") {
                    let value = String(trimmed.dropFirst("#html:".count)).trimmingCharacters(in: .whitespaces).lowercased()
                    isHTML = value == "true"
                } else if lower.hasPrefix("#deck column:") {
                    if let col = Int(String(trimmed.dropFirst("#deck column:".count)).trimmingCharacters(in: .whitespaces)) {
                        deckColumnIndex = col - 1 // Convert 1-indexed to 0-indexed
                    }
                }
            } else if !trimmed.isEmpty {
                dataLines.append(trimmed)
            }
        }

        // If no metadata detected separator, auto-detect
        let hasMetadata = lines.contains { $0.trimmingCharacters(in: .whitespaces).hasPrefix("#separator:") }
        if !hasMetadata {
            let tabCount = dataLines.filter { $0.contains("\t") }.count
            if tabCount < dataLines.count / 2 {
                let commaCount = dataLines.filter { $0.contains(",") }.count
                if commaCount > dataLines.count / 2 {
                    separator = ","
                }
            }
        }

        // First pass: find root deck name from :: paths
        var rootDeckName: String? = nil
        if let deckCol = deckColumnIndex {
            for line in dataLines {
                let fields = line.components(separatedBy: separator)
                if fields.count > deckCol {
                    let deckPath = fields[deckCol].trimmingCharacters(in: .whitespacesAndNewlines)
                    let parts = deckPath.components(separatedBy: "::")
                    if parts.count > 1 {
                        rootDeckName = parts[0].trimmingCharacters(in: .whitespaces)
                        break
                    }
                }
            }
        }

        // Second pass: parse all cards
        let cards: [ParsedCard] = dataLines.compactMap { line in
            let fields = line.components(separatedBy: separator)
            guard fields.count >= 2 else { return nil }

            var front = fields[0].trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            var back = fields[1].trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\""))

            // Handle HTML: convert <br> to newline first, then strip remaining tags
            if isHTML {
                back = back
                    .replacingOccurrences(of: "<br>", with: "\n", options: .caseInsensitive)
                    .replacingOccurrences(of: "<br/>", with: "\n", options: .caseInsensitive)
                    .replacingOccurrences(of: "<br />", with: "\n", options: .caseInsensitive)
                front = front
                    .replacingOccurrences(of: "<br>", with: "\n", options: .caseInsensitive)
                    .replacingOccurrences(of: "<br/>", with: "\n", options: .caseInsensitive)
                    .replacingOccurrences(of: "<br />", with: "\n", options: .caseInsensitive)
            }
            front = stripHTML(front).trimmingCharacters(in: .whitespacesAndNewlines)
            back = stripHTML(back).trimmingCharacters(in: .whitespacesAndNewlines)

            guard !front.isEmpty && !back.isEmpty else { return nil }

            // Extract subdeck from deck column
            var subdeck = ""
            if let deckCol = deckColumnIndex, fields.count > deckCol {
                let deckPath = fields[deckCol].trimmingCharacters(in: .whitespacesAndNewlines)
                let parts = deckPath.components(separatedBy: "::")
                if parts.count > 1 {
                    subdeck = parts.dropFirst().map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: "::")
                }
            }

            return ParsedCard(front: front, back: back, subdeck: subdeck)
        }

        return (cards, rootDeckName)
    }

    private func stripHTML(_ string: String) -> String {
        string.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    // MARK: - Create / Merge / Delete
    private func createDeck() {
        let name = deckName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !pendingCards.isEmpty else { return }

        // Check if deck with this name already exists
        if let existing = decks.first(where: { $0.name == name }) {
            existingDeckForMerge = existing
            showMergePrompt = true
            return
        }

        let deck = CustomDeck(name: name)
        modelContext.insert(deck)

        for card in pendingCards {
            let customCard = CustomCard(front: card.front, back: card.back, subdeck: card.subdeck, deck: deck)
            modelContext.insert(customCard)
        }

        try? modelContext.save()
        pendingCards = []
        deckName = ""
    }

    private func mergeDeck() {
        guard let existing = existingDeckForMerge else { return }
        let existingFronts = Set(existing.cards.map { $0.front })

        var added = 0
        for card in pendingCards where !existingFronts.contains(card.front) {
            let customCard = CustomCard(front: card.front, back: card.back, subdeck: card.subdeck, deck: existing)
            modelContext.insert(customCard)
            added += 1
        }

        // Also update subdeck info for existing cards that might not have had it
        for card in pendingCards where existingFronts.contains(card.front) && !card.subdeck.isEmpty {
            if let existingCard = existing.cards.first(where: { $0.front == card.front }),
               (existingCard.subdeck ?? "").isEmpty {
                existingCard.subdeck = card.subdeck
            }
        }

        try? modelContext.save()
        pendingCards = []
        deckName = ""
        existingDeckForMerge = nil
    }

    private func deleteDeck(_ deck: CustomDeck) {
        withAnimation(.spring(response: 0.3)) {
            modelContext.delete(deck)
            try? modelContext.save()
        }
    }
}

// MARK: - Custom Deck Card
struct CustomDeckCard: View {
    let deck: CustomDeck
    let onDelete: () -> Void
    @State private var isExpanded = false

    private var studied: Int {
        deck.cards.filter { $0.repetitions >= 1 }.count
    }

    private var total: Int {
        deck.cards.count
    }

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(studied) / Double(total)
    }

    private var isCompleted: Bool {
        total > 0 && studied >= total
    }

    private var subdeckNames: [String] {
        let names = Set(deck.cards.compactMap { name -> String? in
            guard let s = name.subdeck, !s.isEmpty else { return nil }
            return s
        })
        return names.sorted()
    }

    private var hasSubdecks: Bool {
        !subdeckNames.isEmpty
    }

    private func subdeckStats(_ name: String) -> (total: Int, studied: Int) {
        let cards = deck.cards.filter { ($0.subdeck ?? "") == name }
        let studiedCount = cards.filter { $0.repetitions >= 1 }.count
        return (cards.count, studiedCount)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main deck info
            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    // Deck icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.customTeal, AppTheme.customTeal.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)

                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(deck.name)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(AppTheme.primaryText)
                                .lineLimit(1)

                            Spacer()

                            Button {
                                onDelete()
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppTheme.tertiaryText)
                                    .padding(6)
                                    .background(
                                        Circle().fill(AppTheme.tertiaryText.opacity(0.08))
                                    )
                            }
                            .buttonStyle(.plain)

                            if isCompleted {
                                HStack(spacing: 3) {
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 8))
                                    Text("Completed")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(AppTheme.goldAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(AppTheme.goldAccent.opacity(0.12))
                                )
                            } else {
                                let remaining = total - studied
                                Text("\(remaining) left")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(AppTheme.danger)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule().fill(AppTheme.danger.opacity(0.10))
                                    )
                            }
                        }

                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(AppTheme.customTeal.opacity(0.12))
                                    .frame(height: 8)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        isCompleted ?
                                        LinearGradient(colors: [AppTheme.goldAccent, AppTheme.goldAccent.opacity(0.7)], startPoint: .leading, endPoint: .trailing) :
                                        LinearGradient(colors: [AppTheme.customTeal, AppTheme.customTeal.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .frame(width: max(geometry.size.width * progress, 0), height: 8)
                            }
                        }
                        .frame(height: 8)

                        // Stats row
                        HStack {
                            HStack(spacing: 4) {
                                Text("\(studied)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(AppTheme.customTeal)
                                Text("of \(total) learned")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }

                            if !isCompleted {
                                let remaining = total - studied
                                Text("\u{2022}")
                                    .font(.caption2)
                                    .foregroundStyle(AppTheme.tertiaryText)
                                HStack(spacing: 2) {
                                    Image(systemName: "flag.fill")
                                        .font(.system(size: 8))
                                    Text("\(remaining) to finish")
                                        .font(.caption2.weight(.medium))
                                }
                                .foregroundStyle(AppTheme.coral)
                            }

                            Spacer()
                        }
                    }
                }

                // Action row
                HStack(spacing: 10) {
                    NavigationLink {
                        CustomStudyView(deck: deck)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 10))
                            Text(hasSubdecks ? "Study All" : "Study")
                                .font(.caption.weight(.bold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(AppTheme.customTeal)
                        )
                    }
                    .buttonStyle(.plain)

                    if hasSubdecks {
                        Spacer()

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isExpanded.toggle()
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Text("\(subdeckNames.count) Lessons")
                                    .font(.caption.weight(.semibold))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9, weight: .semibold))
                                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            }
                            .foregroundStyle(AppTheme.customTeal)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(AppTheme.customTeal.opacity(0.10))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(14)

            // Expanded subdecks
            if isExpanded && hasSubdecks {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(AppTheme.customTeal.opacity(0.10))
                        .frame(height: 1)

                    VStack(spacing: 2) {
                        ForEach(subdeckNames, id: \.self) { name in
                            let stats = subdeckStats(name)
                            NavigationLink {
                                CustomStudyView(deck: deck, subdeck: name)
                            } label: {
                                SubdeckRow(name: name, total: stats.total, studied: stats.studied)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white)
                .shadow(color: isCompleted ? .clear : .black.opacity(0.05), radius: 6, y: 2)
        )
        .modifier(ConditionalShimmer(isActive: isCompleted))
    }
}

// MARK: - Subdeck Row
private struct SubdeckRow: View {
    let name: String
    let total: Int
    let studied: Int

    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(studied) / Double(total)
    }

    private var isCompleted: Bool {
        total > 0 && studied >= total
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isCompleted ? AppTheme.goldAccent.opacity(0.12) : AppTheme.customTeal.opacity(0.08))
                    .frame(width: 32, height: 32)

                Image(systemName: isCompleted ? "checkmark.circle.fill" : "book.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(isCompleted ? AppTheme.goldAccent : AppTheme.customTeal)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(AppTheme.customTeal.opacity(0.10))
                            .frame(height: 5)

                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(
                                isCompleted ?
                                LinearGradient(colors: [AppTheme.goldAccent, AppTheme.goldAccent.opacity(0.7)], startPoint: .leading, endPoint: .trailing) :
                                LinearGradient(colors: [AppTheme.customTeal, AppTheme.customTeal.opacity(0.5)], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: max(geometry.size.width * progress, 0), height: 5)
                    }
                }
                .frame(height: 5)
            }

            HStack(spacing: 3) {
                Text("\(studied)/\(total)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isCompleted ? AppTheme.goldAccent : AppTheme.customTeal)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isCompleted ? AppTheme.goldAccent.opacity(0.04) : Color.clear)
        )
    }
}
