import SwiftUI

struct LegalDocumentDetailView: View {
    let circleId: Int
    let documentId: Int

    @Environment(AppRouter.self) private var router
    @State private var document: LegalDocument?
    @State private var files: [LegalDocumentFile] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView(message: "Loading document...")
            } else if let error = errorMessage {
                ErrorView(message: error) {
                    Task {
                        await loadDocument()
                    }
                }
            } else if let document = document {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header Card
                        headerCard(document: document)

                        // Status Card
                        statusCard(document: document)

                        // Details Card
                        detailsCard(document: document)

                        // Attorney Card
                        if hasAttorneyInfo(document: document) {
                            attorneyCard(document: document)
                        }

                        // Files Card
                        filesCard(document: document)

                        // Notes Card
                        if let notes = document.notes, !notes.isEmpty {
                            notesCard(notes: notes)
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle(document?.name ?? "Legal Document")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadDocument()
        }
    }

    // MARK: - Load Data

    private func loadDocument() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: LegalDocumentDetailResponse = try await APIClient.shared.request(.legalDocument(id: documentId))
            document = response.legalDocument
            files = response.files ?? []
        } catch {
            errorMessage = "Failed to load document"
        }

        isLoading = false
    }

    // MARK: - Header Card

    private func headerCard(document: LegalDocument) -> some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(iconColor(for: document.documentType).opacity(0.15))
                    .frame(width: 72, height: 72)

                Image(systemName: document.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(iconColor(for: document.documentType))
            }

            // Title
            VStack(spacing: 8) {
                Text(document.name ?? "Untitled Document")
                    .font(AppTypography.displaySmall)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(document.documentTypeName ?? "Legal Document")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(AppColors.background)
        .cornerRadius(16)
    }

    // MARK: - Status Card

    private func statusCard(document: LegalDocument) -> some View {
        HStack(spacing: 16) {
            // Status
            VStack(alignment: .leading, spacing: 4) {
                Text("Status")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textTertiary)

                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor(for: document.status))
                        .frame(width: 8, height: 8)

                    Text(document.statusName ?? "Unknown")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Expiration Warning
            if document.isExpired == true {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Expired")
                        .font(AppTypography.caption)
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            } else if document.isExpiringSoon == true {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    Text("Expiring Soon")
                        .font(AppTypography.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(12)
    }

    // MARK: - Details Card

    private func detailsCard(document: LegalDocument) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Document Details")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 12) {
                if let executionDate = document.formattedExecutionDate {
                    LegalDetailRow(label: "Execution Date", value: executionDate)
                }

                if let expirationDate = document.expirationDate {
                    LegalDetailRow(label: "Expiration Date", value: formatDate(expirationDate))
                }

                if let digitalCopyDate = document.digitalCopyDate {
                    LegalDetailRow(label: "Digital Copy Date", value: formatDate(digitalCopyDate))
                }

                if let location = document.originalLocation, !location.isEmpty {
                    LegalDetailRow(label: "Location of Original", value: location)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.background)
        .cornerRadius(12)
    }

    // MARK: - Attorney Card

    private func hasAttorneyInfo(document: LegalDocument) -> Bool {
        return (document.attorneyName != nil && !document.attorneyName!.isEmpty) ||
               (document.attorneyFirm != nil && !document.attorneyFirm!.isEmpty) ||
               (document.attorneyPhone != nil && !document.attorneyPhone!.isEmpty) ||
               (document.attorneyEmail != nil && !document.attorneyEmail!.isEmpty)
    }

    private func attorneyCard(document: LegalDocument) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.text.rectangle")
                    .foregroundColor(AppColors.primary)
                Text("Attorney Information")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }

            VStack(spacing: 12) {
                if let name = document.attorneyName, !name.isEmpty {
                    LegalDetailRow(label: "Name", value: name)
                }

                if let firm = document.attorneyFirm, !firm.isEmpty {
                    LegalDetailRow(label: "Firm", value: firm)
                }

                if let phone = document.attorneyPhone, !phone.isEmpty {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Phone")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textTertiary)

                            Text(phone)
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textPrimary)
                        }

                        Spacer()

                        Link(destination: URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))")!) {
                            Image(systemName: "phone.fill")
                                .foregroundColor(AppColors.primary)
                        }
                    }
                }

                if let email = document.attorneyEmail, !email.isEmpty {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email")
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textTertiary)

                            Text(email)
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textPrimary)
                        }

                        Spacer()

                        Link(destination: URL(string: "mailto:\(email)")!) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(AppColors.primary)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.background)
        .cornerRadius(12)
    }

    // MARK: - Files Card

    private func filesCard(document: LegalDocument) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Files")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                let count = files.count
                Text("\(count) file\(count == 1 ? "" : "s")")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            if !files.isEmpty {
                VStack(spacing: 8) {
                    ForEach(files) { file in
                        LegalFileRow(file: file)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.textTertiary)

                    Text("No files uploaded")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.background)
        .cornerRadius(12)
    }

    // MARK: - Notes Card

    private func notesCard(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            Text(stripHTML(from: notes))
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.background)
        .cornerRadius(12)
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
        // Fallback: simple regex strip
        return string.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    // MARK: - Helpers

    private func iconColor(for type: String?) -> Color {
        switch type {
        case "will": return .purple
        case "trust": return .blue
        case "power_of_attorney": return .orange
        case "medical_directive": return .pink
        default: return .gray
        }
    }

    private func statusColor(for status: String?) -> Color {
        switch status {
        case "active": return .green
        case "superseded": return .orange
        case "expired": return .red
        case "revoked": return .gray
        default: return .gray
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Legal File Row

struct LegalFileRow: View {
    let file: LegalDocumentFile
    @State private var showImageViewer = false

    var body: some View {
        Button {
            if file.isImage == true {
                showImageViewer = true
            } else if let viewUrl = file.viewUrl, let url = URL(string: viewUrl) {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 12) {
                // Image Thumbnail or File Icon
                if file.isImage == true, let viewUrl = file.viewUrl {
                    AsyncImage(url: URL(string: viewUrl)) { phase in
                        switch phase {
                        case .empty:
                            fileIconView
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure:
                            fileIconView
                        @unknown default:
                            fileIconView
                        }
                    }
                    .frame(width: 44, height: 44)
                } else {
                    fileIconView
                }

                // File Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)

                    if let size = file.formattedSize {
                        Text(size)
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }

                Spacer()

                // View indicator
                Image(systemName: file.isImage == true ? "arrow.up.left.and.arrow.down.right" : "eye")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(12)
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showImageViewer) {
            if let viewUrl = file.viewUrl {
                LegalImageViewerSheet(imageUrl: viewUrl, fileName: file.name)
            }
        }
    }

    private var fileIconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .frame(width: 44, height: 44)

            Image(systemName: fileIcon)
                .font(.system(size: 20))
                .foregroundColor(fileIconColor)
        }
    }

    private var fileIcon: String {
        if file.isImage == true {
            return "photo"
        } else if file.isPdf == true {
            return "doc.richtext"
        } else {
            return "doc"
        }
    }

    private var fileIconColor: Color {
        if file.isImage == true {
            return .teal
        } else if file.isPdf == true {
            return .red
        } else {
            return .gray
        }
    }
}

// MARK: - Legal Image Viewer Sheet

struct LegalImageViewerSheet: View {
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

// MARK: - Legal Detail Row

struct LegalDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textTertiary)

            Text(value)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        LegalDocumentDetailView(circleId: 1, documentId: 1)
            .environment(AppRouter())
    }
}
