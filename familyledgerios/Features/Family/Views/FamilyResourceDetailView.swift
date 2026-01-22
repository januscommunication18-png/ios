import SwiftUI

struct FamilyResourceDetailView: View {
    let circleId: Int
    let resourceId: Int

    @Environment(AppRouter.self) private var router
    @State private var resource: FamilyResource?
    @State private var files: [ResourceFile] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView(message: "Loading resource...")
            } else if let error = errorMessage {
                ErrorView(message: error) {
                    Task {
                        await loadResource()
                    }
                }
            } else if let resource = resource {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header Card
                        headerCard(resource: resource)

                        // Details Card
                        detailsCard(resource: resource)

                        // Files Card
                        filesCard(resource: resource)

                        // Notes Card
                        if let notes = resource.notes, !notes.isEmpty {
                            notesCard(notes: notes)
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle(resource?.name ?? "Resource")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadResource()
        }
    }

    // MARK: - Load Data

    private func loadResource() async {
        isLoading = true
        errorMessage = nil

        do {
            let response: ResourceDetailResponse = try await APIClient.shared.request(.resource(id: resourceId))
            resource = response.resource
            files = response.files ?? []
        } catch {
            errorMessage = "Failed to load resource"
        }

        isLoading = false
    }

    // MARK: - Header Card

    private func headerCard(resource: FamilyResource) -> some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(iconColor(for: resource.documentType).opacity(0.15))
                    .frame(width: 72, height: 72)

                Image(systemName: resource.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(iconColor(for: resource.documentType))
            }

            // Title and Status
            VStack(spacing: 8) {
                Text(resource.name)
                    .font(AppTypography.displaySmall)
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                HStack(spacing: 12) {
                    if let status = resource.statusName {
                        SmallBadge(text: status, color: statusColor(for: resource.status))
                    }

                    Text(resource.documentTypeName ?? "Resource")
                        .font(AppTypography.caption)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(AppColors.background)
        .cornerRadius(16)
    }

    // MARK: - Details Card

    private func detailsCard(resource: FamilyResource) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Resource Details")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 12) {
                if let date = resource.digitalCopyDate {
                    ResourceDetailRow(label: "Digital Copy Date", value: formatDate(date))
                }

                if let location = resource.originalLocation, !location.isEmpty {
                    ResourceDetailRow(label: "Location of Original", value: location)
                }

                if resource.documentType == "other", let customType = resource.customDocumentType, !customType.isEmpty {
                    ResourceDetailRow(label: "Custom Type", value: customType)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.background)
        .cornerRadius(12)
    }

    // MARK: - Files Card

    private func filesCard(resource: FamilyResource) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Files")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Text("\(files.count) file\(files.count == 1 ? "" : "s")")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            if !files.isEmpty {
                VStack(spacing: 8) {
                    ForEach(files) { file in
                        FileRow(file: file)
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
        case "emergency": return .red
        case "evacuation_plan": return .orange
        case "fire_extinguisher": return .pink
        case "rental_agreement": return .blue
        case "home_warranty": return .green
        default: return .gray
        }
    }

    private func statusColor(for status: String?) -> Color {
        switch status {
        case "active": return .green
        case "expired": return .red
        case "archived": return .gray
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

// MARK: - File Row

struct FileRow: View {
    let file: ResourceFile
    @State private var showImageViewer = false
    @State private var isDownloading = false
    @State private var showDownloadSuccess = false

    var body: some View {
        Button {
            if file.isImage == true {
                showImageViewer = true
            } else if file.isPdf == true {
                downloadFile()
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
                    Text(file.displayName)
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

                // Action indicator
                if isDownloading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if showDownloadSuccess {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: actionIcon)
                        .font(.system(size: 16))
                        .foregroundColor(file.isPdf == true ? AppColors.primary : AppColors.textTertiary)
                }
            }
            .padding(12)
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .disabled(isDownloading)
        .fullScreenCover(isPresented: $showImageViewer) {
            if let viewUrl = file.viewUrl {
                ImageViewerSheet(imageUrl: viewUrl, fileName: file.displayName)
            }
        }
    }

    private var actionIcon: String {
        if file.isImage == true {
            return "arrow.up.left.and.arrow.down.right"
        } else if file.isPdf == true {
            return "arrow.down.circle.fill"
        } else {
            return "eye"
        }
    }

    private func downloadFile() {
        guard let downloadUrlString = file.downloadUrl ?? file.viewUrl,
              let url = URL(string: downloadUrlString) else { return }

        isDownloading = true

        Task {
            do {
                let (localUrl, _) = try await URLSession.shared.download(from: url)

                // Move to documents directory
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let destinationUrl = documentsPath.appendingPathComponent(file.displayName)

                // Remove existing file if exists
                try? FileManager.default.removeItem(at: destinationUrl)
                try FileManager.default.moveItem(at: localUrl, to: destinationUrl)

                await MainActor.run {
                    isDownloading = false
                    showDownloadSuccess = true

                    // Share/open the file
                    let activityVC = UIActivityViewController(activityItems: [destinationUrl], applicationActivities: nil)
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootVC = windowScene.windows.first?.rootViewController {
                        rootVC.present(activityVC, animated: true)
                    }

                    // Reset success icon after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showDownloadSuccess = false
                    }
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                    print("Download failed: \(error)")
                }
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

// MARK: - Resource Detail Row

struct ResourceDetailRow: View {
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

// MARK: - Image Viewer Sheet

struct ImageViewerSheet: View {
    let imageUrl: String
    let fileName: String
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var loadedImage: UIImage?
    @State private var isLoading = true
    @State private var loadError = false

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
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            Text(imageUrl)
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .lineLimit(3)
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

        print("Loading image from URL: \(imageUrl)")

        guard let url = URL(string: imageUrl) else {
            print("Invalid URL: \(imageUrl)")
            isLoading = false
            loadError = true
            errorMessage = "Invalid URL"
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    errorMessage = "HTTP Error: \(httpResponse.statusCode)"
                    loadError = true
                    isLoading = false
                    return
                }
            }

            print("Data received: \(data.count) bytes")

            if let image = UIImage(data: data) {
                loadedImage = image
                print("Image loaded successfully")
            } else {
                print("Failed to create UIImage from data")
                loadError = true
                errorMessage = "Invalid image data"
            }
        } catch {
            print("Error loading image: \(error.localizedDescription)")
            loadError = true
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    @State private var errorMessage: String?
}

#Preview {
    NavigationStack {
        FamilyResourceDetailView(circleId: 1, resourceId: 1)
            .environment(AppRouter())
    }
}
