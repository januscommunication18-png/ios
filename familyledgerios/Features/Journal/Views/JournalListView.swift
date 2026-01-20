import SwiftUI

@Observable
final class JournalViewModel {
    var entries: [JournalEntry] = []
    var selectedEntry: JournalEntry?
    var isLoading = false
    var errorMessage: String?

    var title = ""
    var content = ""
    var mood: String?
    var type: String = "journal"

    @MainActor
    func loadEntries() async {
        isLoading = entries.isEmpty
        do {
            let response: JournalResponse = try await APIClient.shared.request(.journal)
            entries = response.entries ?? []
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to load entries"
        }
        isLoading = false
    }

    @MainActor
    func loadEntry(id: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            let response: JournalEntryDetailResponse = try await APIClient.shared.request(.journalEntry(id: id))
            selectedEntry = response.entry
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to load entry: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

struct JournalListView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = JournalViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading journal...")
            } else if viewModel.entries.isEmpty {
                EmptyStateView.noJournalEntries { router.navigate(to: .createJournalEntry) }
            } else {
                List(viewModel.entries) { entry in
                    Button { router.navigate(to: .journalEntry(id: entry.id)) } label: {
                        HStack {
                            if let mood = entry.mood { Text(moodEmoji(mood)) }
                            VStack(alignment: .leading) {
                                Text(entry.title ?? "Untitled").font(AppTypography.headline)
                                Text(entry.date ?? "").font(AppTypography.caption).foregroundColor(AppColors.textSecondary)
                            }
                            Spacer()
                            if entry.isPinned == true { Image(systemName: "pin.fill").foregroundColor(AppColors.warning) }
                        }
                    }
                }
            }
        }
        .navigationTitle("Journal")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { router.navigate(to: .createJournalEntry) } label: { Image(systemName: "plus") }
            }
        }
        .task { await viewModel.loadEntries() }
    }

    private func moodEmoji(_ mood: String) -> String {
        switch mood.lowercased() {
        case "happy": return "😊"
        case "sad": return "😢"
        case "anxious": return "😰"
        case "excited": return "🎉"
        case "calm": return "😌"
        case "angry": return "😠"
        case "grateful": return "🙏"
        case "tired": return "😴"
        default: return "😐"
        }
    }
}

struct JournalDetailView: View {
    let entryId: Int
    @State private var viewModel = JournalViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading entry...")
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task {
                        await viewModel.loadEntry(id: entryId)
                    }
                }
            } else if let entry = viewModel.selectedEntry {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header Card
                        headerCard(entry: entry)

                        // Title
                        if let title = entry.title, !title.isEmpty {
                            Text(title)
                                .font(AppTypography.displaySmall)
                                .foregroundColor(AppColors.textPrimary)
                        }

                        // Content Card
                        if let content = entry.content, !content.isEmpty {
                            contentCard(content: content)
                        }

                        // Photos
                        if let attachments = entry.attachments {
                            let photos = attachments.filter { $0.type == "photo" }
                            let files = attachments.filter { $0.type != "photo" }

                            if !photos.isEmpty {
                                photosSection(photos: photos)
                            }

                            if !files.isEmpty {
                                filesSection(files: files)
                            }
                        }

                        // Tags
                        if let tags = entry.tags, !tags.isEmpty {
                            tagsSection(tags: tags)
                        }

                        // Meta Footer
                        metaFooter(entry: entry)
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            } else {
                VStack {
                    Text("No entry found")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .navigationTitle("Entry")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadEntry(id: entryId) }
    }

    // MARK: - Header Card

    private func headerCard(entry: JournalEntry) -> some View {
        VStack(spacing: 16) {
            HStack {
                // Type icon and label
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(typeColor(entry.type).opacity(0.15))
                            .frame(width: 48, height: 48)

                        Image(systemName: typeIcon(entry.type))
                            .font(.system(size: 22))
                            .foregroundColor(typeColor(entry.type))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(entry.typeLabel ?? entry.type?.capitalized ?? "Journal")
                                .font(AppTypography.caption)
                                .foregroundColor(typeColor(entry.type))

                            if entry.isDraft == true {
                                Badge(text: "Draft", color: .orange)
                            }

                            if entry.isPinned == true {
                                Image(systemName: "pin.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                            }
                        }

                        // Date and time
                        HStack(spacing: 4) {
                            if let formattedDate = entry.formattedDate {
                                Text(formattedDate)
                                    .font(AppTypography.captionSmall)
                                    .foregroundColor(AppColors.textSecondary)
                            } else if let date = entry.date {
                                Text(date)
                                    .font(AppTypography.captionSmall)
                                    .foregroundColor(AppColors.textSecondary)
                            }

                            if let time = entry.time {
                                Text("at \(time)")
                                    .font(AppTypography.captionSmall)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                    }
                }

                Spacer()

                // Mood and visibility
                HStack(spacing: 12) {
                    if let moodEmoji = entry.moodEmoji {
                        Text(moodEmoji)
                            .font(.system(size: 32))
                    } else if let mood = entry.mood {
                        Text(moodEmoji(mood))
                            .font(.system(size: 32))
                    }

                    Image(systemName: visibilityIcon(entry.visibility))
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    // MARK: - Content Card

    private func contentCard(content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(stripHTML(from: content))
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.background)
        .cornerRadius(12)
    }

    // MARK: - Photos Section

    private func photosSection(photos: [JournalAttachment]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo.on.rectangle")
                    .foregroundColor(AppColors.textSecondary)
                Text("Photos")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Text("\(photos.count) photo\(photos.count == 1 ? "" : "s")")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(photos) { photo in
                    JournalPhotoThumbnail(photo: photo)
                }
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(12)
    }

    // MARK: - Files Section

    private func filesSection(files: [JournalAttachment]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundColor(AppColors.textSecondary)
                Text("Files")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Text("\(files.count) file\(files.count == 1 ? "" : "s")")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)
            }

            ForEach(files) { file in
                JournalFileRow(file: file)
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(12)
    }

    // MARK: - Tags Section

    private func tagsSection(tags: [JournalTag]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tag")
                    .foregroundColor(AppColors.textSecondary)
                Text("Tags")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }

            FlowLayout(spacing: 8) {
                ForEach(tags) { tag in
                    Text(tag.name)
                        .font(AppTypography.captionSmall)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.primary.opacity(0.1))
                        .foregroundColor(AppColors.primary)
                        .cornerRadius(16)
                }
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(12)
    }

    // MARK: - Meta Footer

    private func metaFooter(entry: JournalEntry) -> some View {
        HStack {
            if let createdAt = entry.createdAt {
                Text("Created \(formatRelativeDate(createdAt))")
                    .font(AppTypography.captionSmall)
                    .foregroundColor(AppColors.textTertiary)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: visibilityIcon(entry.visibility))
                    .font(.system(size: 10))
                Text(entry.visibilityLabel ?? "Private")
                    .font(AppTypography.captionSmall)
            }
            .foregroundColor(AppColors.textTertiary)
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(12)
    }

    // MARK: - Helper Functions

    private func typeIcon(_ type: String?) -> String {
        switch type {
        case "journal": return "book.fill"
        case "memory": return "heart.fill"
        case "note": return "doc.text.fill"
        case "milestone": return "trophy.fill"
        default: return "book.fill"
        }
    }

    private func typeColor(_ type: String?) -> Color {
        switch type {
        case "journal": return AppColors.primary
        case "memory": return .pink
        case "note": return .orange
        case "milestone": return .green
        default: return AppColors.primary
        }
    }

    private func visibilityIcon(_ visibility: String?) -> String {
        switch visibility {
        case "private": return "lock.fill"
        case "family": return "person.2.fill"
        default: return "person.badge.check.fill"
        }
    }

    private func moodEmoji(_ mood: String) -> String {
        switch mood.lowercased() {
        case "happy": return "😊"
        case "sad": return "😢"
        case "anxious": return "😰"
        case "excited": return "🎉"
        case "calm": return "😌"
        case "angry": return "😠"
        case "grateful": return "🙏"
        case "tired": return "😴"
        default: return "😐"
        }
    }

    private func stripHTML(from string: String) -> String {
        guard let data = string.data(using: .utf8) else { return string }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributedString.string
        }
        return string.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    private func formatRelativeDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else { return dateString }

        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .full
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Journal Photo Thumbnail

struct JournalPhotoThumbnail: View {
    let photo: JournalAttachment
    @State private var showImageViewer = false

    var body: some View {
        Button {
            showImageViewer = true
        } label: {
            if let url = photo.url {
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .aspectRatio(1, contentMode: .fit)
                            .cornerRadius(8)
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fill)
                            .clipped()
                            .cornerRadius(8)
                    case .failure:
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .aspectRatio(1, contentMode: .fit)
                            .cornerRadius(8)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(AppColors.textTertiary)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(8)
            }
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showImageViewer) {
            if let url = photo.url {
                JournalImageViewerSheet(imageUrl: url, fileName: photo.fileName ?? "Photo")
            }
        }
    }
}

// MARK: - Journal Image Viewer Sheet

struct JournalImageViewerSheet: View {
    let imageUrl: String
    let fileName: String
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    @State private var loadError = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    } else if let uiImage = loadedImage {
                        ScrollView([.horizontal, .vertical], showsIndicators: false) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(scale)
                                .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            scale = value
                                        }
                                        .onEnded { _ in
                                            withAnimation {
                                                scale = max(1.0, min(scale, 4.0))
                                            }
                                        }
                                )
                                .onTapGesture(count: 2) {
                                    withAnimation {
                                        scale = scale > 1.0 ? 1.0 : 2.0
                                    }
                                }
                        }
                    } else if loadError {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.red)
                            Text("Failed to load image")
                                .foregroundColor(.white)
                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Button("Try Again") {
                                Task {
                                    await loadImage()
                                }
                            }
                            .buttonStyle(.bordered)
                            .tint(.white)
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .background(Color.black)
            .navigationTitle(fileName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let url = URL(string: imageUrl) {
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        isLoading = true
        loadError = false
        errorMessage = nil

        guard let url = URL(string: imageUrl) else {
            isLoading = false
            loadError = true
            errorMessage = "Invalid URL"
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                errorMessage = "HTTP Error: \(httpResponse.statusCode)"
                loadError = true
                isLoading = false
                return
            }

            if let image = UIImage(data: data) {
                loadedImage = image
            } else {
                loadError = true
                errorMessage = "Invalid image data"
            }
        } catch {
            loadError = true
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

struct CreateJournalEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = JournalViewModel()

    private let moods = ["happy", "sad", "anxious", "excited", "calm", "angry", "grateful", "tired"]

    var body: some View {
        Form {
            TextField("Title", text: $viewModel.title)
            TextEditor(text: $viewModel.content).frame(minHeight: 200)
            Picker("Mood", selection: $viewModel.mood) {
                Text("None").tag(nil as String?)
                ForEach(moods, id: \.self) { mood in
                    Text("\(moodEmoji(mood)) \(mood.capitalized)").tag(mood as String?)
                }
            }
        }
        .navigationTitle("New Entry")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) { Button("Save") { dismiss() }.disabled(viewModel.title.isEmpty) }
        }
    }

    private func moodEmoji(_ mood: String) -> String {
        switch mood.lowercased() {
        case "happy": return "😊"
        case "sad": return "😢"
        case "anxious": return "😰"
        case "excited": return "🎉"
        case "calm": return "😌"
        case "angry": return "😠"
        case "grateful": return "🙏"
        case "tired": return "😴"
        default: return "😐"
        }
    }
}

// MARK: - Journal File Row

struct JournalFileRow: View {
    let file: JournalAttachment

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(width: 44, height: 44)

                Image(systemName: fileIcon)
                    .font(.system(size: 20))
                    .foregroundColor(fileColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(file.fileName ?? "Unknown file")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)

                Text(file.type ?? "file")
                    .font(AppTypography.captionSmall)
                    .foregroundColor(AppColors.textTertiary)
            }

            Spacer()

            if let url = file.url, let fileUrl = URL(string: url) {
                Link(destination: fileUrl) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 22))
                        .foregroundColor(AppColors.primary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }

    private var fileIcon: String {
        let type = file.type?.lowercased() ?? ""
        let fileName = file.fileName?.lowercased() ?? ""

        if type == "pdf" || fileName.hasSuffix(".pdf") {
            return "doc.fill"
        } else if fileName.hasSuffix(".doc") || fileName.hasSuffix(".docx") {
            return "doc.text.fill"
        } else if fileName.hasSuffix(".xls") || fileName.hasSuffix(".xlsx") {
            return "tablecells.fill"
        } else {
            return "doc.fill"
        }
    }

    private var fileColor: Color {
        let fileName = file.fileName?.lowercased() ?? ""

        if fileName.hasSuffix(".pdf") {
            return .red
        } else if fileName.hasSuffix(".doc") || fileName.hasSuffix(".docx") {
            return .blue
        } else if fileName.hasSuffix(".xls") || fileName.hasSuffix(".xlsx") {
            return .green
        } else {
            return .gray
        }
    }
}
