import SwiftUI
import UniformTypeIdentifiers

private struct CSVImportPreviewContext: Identifiable, Hashable {
    let id = UUID()
    let fileName: String
    let totalRows: Int
    let rows: [CSVImportRow]

    var readyRows: [CSVImportRow] {
        rows.filter { $0.disposition == .ready }
    }

    var existingDuplicateRows: [CSVImportRow] {
        rows.filter { $0.disposition == .duplicateExisting }
    }

    var fileDuplicateRows: [CSVImportRow] {
        rows.filter { $0.disposition == .duplicateInFile }
    }

    var invalidRows: [CSVImportRow] {
        rows.filter { $0.disposition == .invalid }
    }

    var duplicateRows: [CSVImportRow] {
        rows.filter { $0.disposition.isDuplicate }
    }
}

private struct CSVImportRow: Identifiable, Hashable {
    let id = UUID()
    let rowNumber: Int
    let reference: String
    let text: String
    let folderName: String
    let masteryStatus: VerseMasteryStatus
    let disposition: CSVImportDisposition
    let message: String?

    var displayReference: String {
        reference.isEmpty ? "Row \(rowNumber)" : reference
    }
}

private enum CSVImportDisposition: String, Hashable {
    case ready
    case duplicateExisting
    case duplicateInFile
    case invalid

    var title: String {
        switch self {
        case .ready:
            return "Ready"
        case .duplicateExisting:
            return "Already Saved"
        case .duplicateInFile:
            return "Duplicate in CSV"
        case .invalid:
            return "Needs Attention"
        }
    }

    var tint: Color {
        switch self {
        case .ready:
            return AppColors.structuralAccent
        case .duplicateExisting, .duplicateInFile:
            return AppColors.warning
        case .invalid:
            return AppColors.weakness
        }
    }

    var isDuplicate: Bool {
        self == .duplicateExisting || self == .duplicateInFile
    }
}

private enum CSVImportError: LocalizedError {
    case unreadableFile
    case invalidCSV
    case missingHeaders
    case noRows

    var errorDescription: String? {
        switch self {
        case .unreadableFile:
            return "That file couldn't be read. Try a different CSV from Files."
        case .invalidCSV:
            return "That file doesn't look like a valid CSV."
        case .missingHeaders:
            return "Your CSV needs recognizable columns for both reference and text."
        case .noRows:
            return "No verse rows were found in that CSV."
        }
    }
}

private enum CSVImportService {
    private enum Column {
        case reference
        case text
        case folder
        case status
    }

    static func parseCSV(from url: URL) throws -> CSVImportPreviewContext {
        let scoped = url.startAccessingSecurityScopedResource()
        defer {
            if scoped {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        let string = try decodeString(from: data)
        let records = try parseRecords(in: string)
        let nonEmptyRecords = records.filter { record in
            record.contains { !normalizedCell($0).isEmpty }
        }

        guard let headerRow = nonEmptyRecords.first else {
            throw CSVImportError.invalidCSV
        }

        let headerMap = headerMapping(for: headerRow)
        guard headerMap[.reference] != nil, headerMap[.text] != nil else {
            throw CSVImportError.missingHeaders
        }

        let existingReferenceKeys = ScriptureAddPipeline.existingReferenceKeys()
        var seenImportReferenceKeys: Set<String> = []
        var rows: [CSVImportRow] = []

        for (index, record) in nonEmptyRecords.dropFirst().enumerated() {
            if record.allSatisfy({ normalizedCell($0).isEmpty }) {
                continue
            }

            let rowNumber = index + 2
            let reference = value(for: .reference, in: record, headerMap: headerMap)
            let text = value(for: .text, in: record, headerMap: headerMap)
            let folder = value(for: .folder, in: record, headerMap: headerMap)
            let status = value(for: .status, in: record, headerMap: headerMap)

            let normalizedReference = normalizeReference(reference)
            let normalizedText = normalizeText(text)
            let normalizedFolder = normalizeFolder(folder)

            let disposition: CSVImportDisposition
            let message: String?
            let resolvedStatus: VerseMasteryStatus

            if normalizedReference.isEmpty && normalizedText.isEmpty {
                disposition = .invalid
                resolvedStatus = .practicing
                message = "Missing reference and text."
            } else if normalizedReference.isEmpty {
                disposition = .invalid
                resolvedStatus = .practicing
                message = "Missing reference."
            } else if normalizedText.isEmpty {
                disposition = .invalid
                resolvedStatus = .practicing
                message = "Missing verse text."
            } else if let resolved = normalizeStatus(status) {
                let referenceKey = ScriptureAddPipeline.normalizedReferenceKey(normalizedReference)
                resolvedStatus = resolved

                if existingReferenceKeys.contains(referenceKey) {
                    disposition = .duplicateExisting
                    message = "A verse with this reference is already in your library."
                } else if seenImportReferenceKeys.contains(referenceKey) {
                    disposition = .duplicateInFile
                    message = "This reference appears more than once in the CSV."
                } else {
                    seenImportReferenceKeys.insert(referenceKey)
                    disposition = .ready
                    message = nil
                }
            } else {
                disposition = .invalid
                resolvedStatus = .practicing
                message = "Status must be Practicing or Memorized."
            }

            rows.append(
                CSVImportRow(
                    rowNumber: rowNumber,
                    reference: normalizedReference,
                    text: normalizedText,
                    folderName: normalizedFolder,
                    masteryStatus: resolvedStatus,
                    disposition: disposition,
                    message: message
                )
            )
        }

        guard !rows.isEmpty else {
            throw CSVImportError.noRows
        }

        return CSVImportPreviewContext(
            fileName: url.lastPathComponent,
            totalRows: rows.count,
            rows: rows
        )
    }

    private static func decodeString(from data: Data) throws -> String {
        let encodings: [String.Encoding] = [.utf8, .utf16, .utf16LittleEndian, .utf16BigEndian]

        for encoding in encodings {
            if let string = String(data: data, encoding: encoding) {
                return string.replacingOccurrences(of: "\u{FEFF}", with: "")
            }
        }

        throw CSVImportError.unreadableFile
    }

    private static func parseRecords(in string: String) throws -> [[String]] {
        let delimiter = detectedDelimiter(in: string)
        var records: [[String]] = []
        var currentRecord: [String] = []
        var currentField = ""
        var isInsideQuotes = false
        var index = string.startIndex

        func finishField() {
            currentRecord.append(currentField)
            currentField = ""
        }

        func finishRecord() {
            finishField()
            records.append(currentRecord)
            currentRecord = []
        }

        while index < string.endIndex {
            let character = string[index]

            if isInsideQuotes {
                if character == "\"" {
                    let nextIndex = string.index(after: index)
                    if nextIndex < string.endIndex, string[nextIndex] == "\"" {
                        currentField.append("\"")
                        index = nextIndex
                    } else {
                        isInsideQuotes = false
                    }
                } else {
                    currentField.append(character)
                }
            } else {
                switch character {
                case "\"":
                    isInsideQuotes = true
                case delimiter:
                    finishField()
                case _ where character.isNewline:
                    finishRecord()
                    let nextIndex = string.index(after: index)
                    if character == "\r", nextIndex < string.endIndex, string[nextIndex] == "\n" {
                        index = nextIndex
                    }
                default:
                    currentField.append(character)
                }
            }

            index = string.index(after: index)
        }

        if isInsideQuotes {
            throw CSVImportError.invalidCSV
        }

        if !currentField.isEmpty || !currentRecord.isEmpty {
            finishRecord()
        }

        return records
    }

    private static func detectedDelimiter(in string: String) -> Character {
        guard let firstContentLine = string
            .split(whereSeparator: \.isNewline)
            .map({ String($0) })
            .first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            return ","
        }

        let candidates: [Character] = [",", ";", "\t"]
        let counts = candidates.map { delimiter in
            (delimiter, firstContentLine.filter { $0 == delimiter }.count)
        }

        return counts.max(by: { $0.1 < $1.1 })?.0 ?? ","
    }

    private static func headerMapping(for headerRow: [String]) -> [Column: Int] {
        var mapping: [Column: Int] = [:]

        for (index, header) in headerRow.enumerated() {
            switch normalizedHeader(header) {
            case "reference", "verse", "versereference", "ref":
                mapping[.reference] = mapping[.reference] ?? index
            case "text", "versetext", "scripture", "content":
                mapping[.text] = mapping[.text] ?? index
            case "folder", "category":
                mapping[.folder] = mapping[.folder] ?? index
            case "status", "state":
                mapping[.status] = mapping[.status] ?? index
            default:
                continue
            }
        }

        return mapping
    }

    private static func normalizedHeader(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }

    private static func value(for column: Column, in record: [String], headerMap: [Column: Int]) -> String {
        guard let index = headerMap[column], record.indices.contains(index) else {
            return ""
        }

        return normalizedCell(record[index])
    }

    private static func normalizedCell(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func normalizeReference(_ value: String) -> String {
        value
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func normalizeText(_ value: String) -> String {
        value
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func normalizeFolder(_ value: String) -> String {
        let normalized = ScriptureAddPipeline.normalizedFolderName(value)
        return normalized.isEmpty ? "Uncategorized" : normalized
    }

    private static func normalizeStatus(_ value: String) -> VerseMasteryStatus? {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !normalized.isEmpty else {
            return .practicing
        }

        switch normalized {
        case "practicing", "practice", "learning", "in progress", "inprogress":
            return .practicing
        case "memorized", "mastered", "memory", "done":
            return .memorized
        default:
            return nil
        }
    }
}

struct ImportReferencesView: View {
    let onSaveVerse: (Verse) -> Void
    let onComplete: (() -> Void)?

    @State private var isShowingFileImporter = false
    @State private var isParsing = false
    @State private var selectedFileName: String?
    @State private var previewContext: CSVImportPreviewContext?
    @State private var message: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                introCard
                fileCard
                helperCard

                if let message {
                    AddFlowMessageCard(
                        message: message,
                        tint: message.contains("ready") ? AppColors.success : AppColors.warning
                    )
                }

                if isParsing {
                    loadingCard
                }

                Button(selectedFileName == nil ? "Choose CSV File" : "Choose Another CSV") {
                    isShowingFileImporter = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity, alignment: .leading)
                .disabled(isParsing)
            }
            .padding(20)
        }
        .background(AppColors.background)
        .navigationTitle("Import CSV")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $previewContext) { context in
            CSVImportPreviewView(
                context: context,
                onSaveVerse: onSaveVerse,
                onComplete: onComplete
            )
        }
        .fileImporter(
            isPresented: $isShowingFileImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText, .text],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Import many verses from one CSV file.")
                .font(.title3.weight(.semibold))

            Text("Choose a CSV from Files, review every row before saving, and bring the valid verses straight into your personal library.")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.selectionFill)
        )
    }

    private var fileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CSV File")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppColors.structuralAccent.opacity(0.12))
                        .frame(width: 46, height: 46)

                    Image(systemName: "doc.text")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppColors.structuralAccent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedFileName ?? "No file selected yet")
                        .font(.headline)
                        .foregroundStyle(AppColors.textPrimary)

                    Text(selectedFileName == nil ? "Pick a CSV from Files to begin." : "You can review everything before anything is saved.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer(minLength: 0)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.surface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        }
    }

    private var helperCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expected columns")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)

            Text("Required: reference, text")
                .font(.subheadline)
                .foregroundStyle(AppColors.textPrimary)

            Text("Optional: folder, status")
                .font(.subheadline)
                .foregroundStyle(AppColors.textPrimary)

            Text("Example CSV")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            Text(
                """
                reference,text,folder,status
                John 3:16,For God so loved the world...,Salvation,Memorized
                Romans 8:28,And we know that all things...,Promises,Practicing
                """
            )
            .font(.system(.footnote, design: .monospaced))
            .foregroundStyle(AppColors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppColors.secondarySurface)
            )
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    private var loadingCard: some View {
        HStack(spacing: 12) {
            SwiftUI.ProgressView()
                .tint(AppColors.structuralAccent)

            Text("Reading your CSV and checking each row...")
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                return
            }

            selectedFileName = url.lastPathComponent
            message = nil

            Task {
                isParsing = true

                do {
                    let context = try CSVImportService.parseCSV(from: url)

                    await MainActor.run {
                        previewContext = context
                        message = importSummaryMessage(for: context)
                        isParsing = false
                    }
                } catch {
                    await MainActor.run {
                        previewContext = nil
                        message = error.localizedDescription
                        isParsing = false
                    }
                }
            }
        case .failure(let error):
            let nsError = error as NSError
            if nsError.code == NSUserCancelledError {
                return
            }

            message = "We couldn't open that file. Try a different CSV."
        }
    }

    private func importSummaryMessage(for context: CSVImportPreviewContext) -> String {
        var parts = ["\(context.readyRows.count) ready"]

        if !context.duplicateRows.isEmpty {
            parts.append("\(context.duplicateRows.count) duplicates")
        }

        if !context.invalidRows.isEmpty {
            parts.append("\(context.invalidRows.count) invalid")
        }

        return parts.joined(separator: " • ")
    }
}

private struct CSVImportPreviewView: View {
    @Environment(\.dismiss) private var dismiss

    let context: CSVImportPreviewContext
    let onSaveVerse: (Verse) -> Void
    let onComplete: (() -> Void)?

    @State private var isSaving = false
    @State private var successMessage: String?

    private let gridColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                summaryCard

                if context.readyRows.isEmpty {
                    AddFlowMessageCard(
                        message: "There are no new verses ready to import from this file.",
                        tint: AppColors.warning
                    )
                }

                if !context.readyRows.isEmpty {
                    sectionCard(
                        title: context.readyRows.count == 1 ? "Ready to Import" : "Ready to Import (\(context.readyRows.count))",
                        subtitle: "These rows will be added to your personal library."
                    ) {
                        ForEach(context.readyRows) { row in
                            rowCard(for: row)
                        }
                    }
                }

                if !context.duplicateRows.isEmpty {
                    sectionCard(
                        title: context.duplicateRows.count == 1 ? "Duplicates" : "Duplicates (\(context.duplicateRows.count))",
                        subtitle: "These rows were recognized, but they will be skipped."
                    ) {
                        ForEach(context.duplicateRows) { row in
                            rowCard(for: row)
                        }
                    }
                }

                if !context.invalidRows.isEmpty {
                    sectionCard(
                        title: context.invalidRows.count == 1 ? "Invalid Row" : "Invalid Rows (\(context.invalidRows.count))",
                        subtitle: "These rows need attention and will not be imported."
                    ) {
                        ForEach(context.invalidRows) { row in
                            rowCard(for: row)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 110)
        }
        .background(AppColors.background)
        .navigationTitle("Import Preview")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            saveBar
        }
        .overlay(alignment: .bottom) {
            if let successMessage {
                FeedbackToast(message: successMessage, systemImage: "checkmark.circle.fill")
                    .padding(.horizontal, 20)
                    .padding(.bottom, 90)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: successMessage)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(summaryTitle)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)

            Text(context.fileName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)

            LazyVGrid(columns: gridColumns, spacing: 10) {
                summaryMetric(title: "Rows", value: "\(context.totalRows)")
                summaryMetric(title: "Ready", value: "\(context.readyRows.count)")
                summaryMetric(title: "Duplicates", value: "\(context.duplicateRows.count)")
                summaryMetric(title: "Invalid", value: "\(context.invalidRows.count)")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppColors.elevatedSurface)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(AppColors.divider, lineWidth: 1)
        }
        .shadow(color: AppColors.shadow, radius: 18, y: 10)
    }

    private func summaryMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    private func sectionCard<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)

            content()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppColors.surface)
        )
    }

    private func rowCard(for row: CSVImportRow) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(row.displayReference)
                        .font(.headline)
                        .foregroundStyle(AppColors.textPrimary)

                    Text("Row \(row.rowNumber)")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer(minLength: 0)

                Text(row.disposition.title)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(row.disposition.tint.opacity(0.14)))
                    .foregroundStyle(row.disposition.tint)
            }

            if !row.text.isEmpty {
                Text(row.text)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(3)
            }

            HStack(spacing: 8) {
                metadataPill(title: row.folderName, tint: AppColors.textSecondary)
                metadataPill(title: row.masteryStatus.rawValue, tint: row.masteryStatus.tintColor)
            }

            if let message = row.message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(row.disposition.tint)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(row.disposition.tint.opacity(0.09))
                    )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppColors.secondarySurface)
        )
    }

    private func metadataPill(title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(tint.opacity(0.12)))
            .foregroundStyle(tint)
    }

    private var saveBar: some View {
        VStack(spacing: 0) {
            Divider()

            Button {
                save()
            } label: {
                Text(isSaving ? "Importing..." : saveButtonTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        Capsule()
                            .fill(context.readyRows.isEmpty ? AppColors.textSecondary : AppColors.structuralAccent)
                    )
            }
            .buttonStyle(.plain)
            .disabled(isSaving || context.readyRows.isEmpty)
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 10)
            .background(.ultraThinMaterial)
        }
    }

    private var summaryTitle: String {
        if context.readyRows.isEmpty {
            return context.duplicateRows.isEmpty ? "Nothing ready to import" : "Everything new was skipped"
        }

        return context.readyRows.count == 1
            ? "1 verse ready to import"
            : "\(context.readyRows.count) verses ready to import"
    }

    private var saveButtonTitle: String {
        context.readyRows.count == 1 ? "Import Verse" : "Import \(context.readyRows.count) Verses"
    }

    private func save() {
        guard !isSaving, !context.readyRows.isEmpty else {
            return
        }

        isSaving = true

        for row in context.readyRows {
            onSaveVerse(
                Verse(
                    reference: row.reference,
                    text: row.text,
                    folderName: row.folderName,
                    isMastered: row.masteryStatus == .memorized
                )
            )
        }

        let skippedCount = context.duplicateRows.count + context.invalidRows.count
        successMessage = skippedCount > 0
            ? "\(context.readyRows.count) imported • \(skippedCount) skipped"
            : (context.readyRows.count == 1 ? "1 verse imported" : "\(context.readyRows.count) verses imported")

        Task {
            try? await Task.sleep(for: .seconds(1.1))
            await MainActor.run {
                isSaving = false
                onComplete?()
                if onComplete == nil {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ImportReferencesView(onSaveVerse: { _ in }, onComplete: nil)
    }
}
