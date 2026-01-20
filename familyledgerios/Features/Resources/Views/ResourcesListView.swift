import SwiftUI

@Observable
final class ResourcesViewModel {
    var resources: [FamilyResource] = []
    var counts: ResourceCounts?
    var selectedResource: FamilyResource?
    var isLoading = false
    var errorMessage: String?

    @MainActor
    func loadResources() async {
        isLoading = resources.isEmpty
        do {
            let response: ResourcesResponse = try await APIClient.shared.request(.resources)
            resources = response.resources ?? []
            counts = response.counts
        }
        catch { errorMessage = "Failed to load resources" }
        isLoading = false
    }

    @MainActor
    func loadResource(id: Int) async {
        isLoading = selectedResource == nil
        do {
            let response: ResourceDetailResponse = try await APIClient.shared.request(.resource(id: id))
            selectedResource = response.resource
        }
        catch { errorMessage = "Failed to load resource" }
        isLoading = false
    }
}

// MARK: - Resource Type

enum ResourceType: String, CaseIterable {
    case emergency = "emergency"
    case evacuationPlan = "evacuation_plan"
    case fireExtinguisher = "fire_extinguisher"
    case rentalAgreement = "rental_agreement"
    case homeWarranty = "home_warranty"
    case other = "other"

    var displayName: String {
        switch self {
        case .emergency: return "Emergency"
        case .evacuationPlan: return "Evacuation Plan"
        case .fireExtinguisher: return "Fire Extinguisher"
        case .rentalAgreement: return "Rental / Lease"
        case .homeWarranty: return "Home Warranty"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .emergency: return "exclamationmark.triangle.fill"
        case .evacuationPlan: return "door.left.hand.open"
        case .fireExtinguisher: return "flame.fill"
        case .rentalAgreement: return "house.fill"
        case .homeWarranty: return "shield.checkered"
        case .other: return "folder.fill"
        }
    }

    var color: Color {
        switch self {
        case .emergency: return .red
        case .evacuationPlan: return .orange
        case .fireExtinguisher: return Color(red: 0.88, green: 0.28, blue: 0.42) // Rose
        case .rentalAgreement: return .blue
        case .homeWarranty: return .green
        case .other: return .gray
        }
    }

    func count(from counts: ResourceCounts?) -> Int {
        guard let counts = counts else { return 0 }
        switch self {
        case .emergency: return counts.emergency ?? 0
        case .evacuationPlan: return counts.evacuation ?? 0
        case .fireExtinguisher: return counts.fire ?? 0
        case .rentalAgreement: return counts.rental ?? 0
        case .homeWarranty: return counts.warranty ?? 0
        case .other: return counts.other ?? 0
        }
    }
}

// MARK: - Resources List View

struct ResourcesListView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = ResourcesViewModel()

    private var totalResources: Int {
        viewModel.counts?.total ?? viewModel.resources.count
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading resources...")
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Document Types Grid (always show)
                        documentTypesGrid

                        // Resources List (always show if we have resources)
                        resourcesListSection
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle("Family Resources")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // TODO: Add resource
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task { await viewModel.loadResources() }
        .refreshable { await viewModel.loadResources() }
    }

    // MARK: - Document Types Grid

    private var documentTypesGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(ResourceType.allCases, id: \.self) { type in
                ResourceTypeCard(
                    type: type,
                    count: type.count(from: viewModel.counts)
                )
            }
        }
    }

    // MARK: - Resources List Section

    private var resourcesListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("All Family Resources")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Button {
                    // TODO: Add resource
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColors.primary)
                }
            }

            if viewModel.resources.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "folder")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.textTertiary)
                    Text("No resources yet")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                    Text("Add your first family resource to get started")
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(viewModel.resources) { resource in
                        ResourceCard(resource: resource) {
                            router.navigate(to: .resource(id: resource.id))
                        }
                    }
                }
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }
}

// MARK: - Resource Type Card

struct ResourceTypeCard: View {
    let type: ResourceType
    let count: Int

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(type.color.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(type.color)
            }

            Text(type.displayName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text("\(count)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color(.systemGray5))
                .cornerRadius(6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(AppColors.background)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Resource Card

struct ResourceCard: View {
    let resource: FamilyResource
    let onTap: () -> Void

    private var typeColor: Color {
        switch resource.documentType {
        case "emergency": return .red
        case "evacuation_plan": return .orange
        case "fire_extinguisher": return Color(red: 0.88, green: 0.28, blue: 0.42)
        case "rental_agreement": return .blue
        case "home_warranty": return .green
        default: return .gray
        }
    }

    private var statusColor: Color {
        switch resource.status?.lowercased() {
        case "active": return .green
        case "expired": return .red
        case "pending": return .orange
        default: return .gray
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .top, spacing: 10) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(typeColor.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: resource.iconName)
                            .font(.system(size: 18))
                            .foregroundColor(typeColor)
                    }

                    // Title & Type
                    VStack(alignment: .leading, spacing: 2) {
                        Text(resource.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Text(resource.documentTypeName ?? resource.documentType?.replacingOccurrences(of: "_", with: " ").capitalized ?? "Other")
                            .font(.system(size: 11))
                            .foregroundColor(AppColors.textTertiary)
                    }

                    Spacer()
                }

                // Status Badge
                HStack {
                    Text(resource.statusName ?? resource.status?.capitalized ?? "Active")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.15))
                        .cornerRadius(6)

                    Spacer()
                }

                // Meta Info
                VStack(alignment: .leading, spacing: 4) {
                    if let date = resource.digitalCopyDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10))
                            Text("Added: \(date)")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(AppColors.textTertiary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 10))
                        Text("\(resource.totalFilesCount) file(s)")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(AppColors.textTertiary)
                }

                // Actions
                HStack(spacing: 12) {
                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "eye")
                            .font(.system(size: 12))
                        Text("View")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
                .padding(.top, 8)
                .overlay(
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 1),
                    alignment: .top
                )
            }
            .padding(12)
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Resource Detail View

struct ResourceDetailView: View {
    let resourceId: Int
    @State private var viewModel = ResourcesViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading...")
            } else if let resource = viewModel.selectedResource {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header Card
                        headerCard(resource)

                        // Resource Details Card
                        resourceDetailsCard(resource)

                        // Files Card
                        filesCard(resource)

                        // Notes Card
                        if let notes = resource.notes, !notes.isEmpty {
                            notesCard(notes)
                        }

                        // Information Card
                        informationCard(resource)
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text("Error Loading Resource")
                        .font(AppTypography.headline)
                    Text(error)
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                    Button("Try Again") {
                        Task { await viewModel.loadResource(id: resourceId) }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading resource...")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Resource Details")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadResource(id: resourceId) }
    }

    // MARK: - Header Card

    private func headerCard(_ resource: FamilyResource) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(typeColor(resource).opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: resource.iconName)
                    .font(.system(size: 26))
                    .foregroundColor(typeColor(resource))
            }

            // Title & Info
            VStack(alignment: .leading, spacing: 8) {
                Text(resource.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                HStack(spacing: 8) {
                    // Status Badge
                    Text(resource.statusName ?? resource.status?.capitalized ?? "Active")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(statusColor(resource))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(resource).opacity(0.15))
                        .cornerRadius(6)

                    // Type
                    Text(resource.documentTypeName ?? resource.documentType?.replacingOccurrences(of: "_", with: " ").capitalized ?? "Other")
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    // MARK: - Resource Details Card

    private func resourceDetailsCard(_ resource: FamilyResource) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Resource Details")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                if let date = resource.digitalCopyDate {
                    DetailItem(label: "Digital Copy Date", value: date)
                }

                if let customType = resource.customDocumentType, !customType.isEmpty {
                    DetailItem(label: "Custom Type", value: customType)
                }

                if let location = resource.originalLocation, !location.isEmpty {
                    DetailItem(label: "Location of Original", value: location, fullWidth: true)
                }

                if let expiration = resource.expirationDate {
                    DetailItem(
                        label: "Expiration Date",
                        value: expiration,
                        valueColor: resource.isExpired == true ? .red : nil
                    )
                }
            }

            if resource.digitalCopyDate == nil && resource.originalLocation == nil && resource.expirationDate == nil {
                Text("No additional details")
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    // MARK: - Files Card

    private func filesCard(_ resource: FamilyResource) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Files")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }

            if let files = resource.files, !files.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(files) { file in
                        FileCard(file: file)
                    }
                }
            } else {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 36))
                        .foregroundColor(AppColors.textTertiary)
                    Text("No files uploaded")
                        .font(AppTypography.bodySmall)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    // MARK: - Notes Card

    private func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            Text(notes.strippingHTML())
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    // MARK: - Information Card

    private func informationCard(_ resource: FamilyResource) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Information")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 12) {
                InfoRow(label: "Type", value: resource.documentTypeName ?? resource.documentType?.replacingOccurrences(of: "_", with: " ").capitalized ?? "Other")

                InfoRow(
                    label: "Status",
                    badgeValue: resource.statusName ?? resource.status?.capitalized ?? "Active",
                    badgeColor: statusColor(resource)
                )

                if let createdAt = resource.createdAt {
                    InfoRow(label: "Created", value: createdAt)
                }

                if let updatedAt = resource.updatedAt {
                    InfoRow(label: "Updated", value: updatedAt)
                }

                if let creator = resource.createdBy {
                    InfoRow(label: "Added by", value: creator.name)
                }

                InfoRow(label: "Files", value: "\(resource.totalFilesCount)")
            }
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    // MARK: - Helper Functions

    private func typeColor(_ resource: FamilyResource) -> Color {
        switch resource.documentType {
        case "emergency": return .red
        case "evacuation_plan": return .orange
        case "fire_extinguisher": return Color(red: 0.88, green: 0.28, blue: 0.42)
        case "rental_agreement": return .blue
        case "home_warranty": return .green
        default: return .gray
        }
    }

    private func statusColor(_ resource: FamilyResource) -> Color {
        switch resource.status?.lowercased() {
        case "active": return .green
        case "expired": return .red
        case "pending": return .orange
        default: return .gray
        }
    }
}

// MARK: - Detail Item

struct DetailItem: View {
    let label: String
    let value: String
    var fullWidth: Bool = false
    var valueColor: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(AppTypography.captionSmall)
                .foregroundColor(AppColors.textTertiary)
            Text(value)
                .font(AppTypography.bodySmall)
                .fontWeight(.medium)
                .foregroundColor(valueColor ?? AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - File Card

struct FileCard: View {
    let file: ResourceFile
    @State private var showingPreview = false

    private var isViewable: Bool {
        file.isImage == true || file.isPdf == true
    }

    private var fileIcon: String {
        if file.isImage == true { return "photo.fill" }
        if file.isPdf == true { return "doc.richtext.fill" }
        return "doc.fill"
    }

    private var iconColor: Color {
        if file.isImage == true { return .teal }
        if file.isPdf == true { return .red }
        return .gray
    }

    private var imageUrl: URL? {
        if file.isImage == true {
            if let urlString = file.viewUrl ?? file.downloadUrl {
                return URL(string: urlString)
            }
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image Preview or File Icon
            if let url = imageUrl {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 100)
                            .clipped()
                            .cornerRadius(8)
                    case .failure:
                        fileIconView
                    case .empty:
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                                .frame(height: 100)
                            ProgressView()
                        }
                    @unknown default:
                        fileIconView
                    }
                }
            } else {
                fileIconView
            }

            // File Info
            VStack(alignment: .leading, spacing: 2) {
                Text(file.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(2)

                if let size = file.formattedSize {
                    Text(size)
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.textTertiary)
                }
            }

            // Actions
            HStack(spacing: 8) {
                if isViewable {
                    Button {
                        showingPreview = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "eye")
                                .font(.system(size: 12))
                            Text("View")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                    }
                }

                Button {
                    // Download action
                    if let urlString = file.downloadUrl, let url = URL(string: urlString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle")
                            .font(.system(size: 12))
                        Text("Download")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
        .sheet(isPresented: $showingPreview) {
            if let urlString = file.viewUrl ?? file.downloadUrl, let url = URL(string: urlString) {
                SafariView(url: url)
            }
        }
    }

    private var fileIconView: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(width: 44, height: 44)
                Image(systemName: fileIcon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
            Spacer()
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let label: String
    var value: String? = nil
    var badgeValue: String? = nil
    var badgeColor: Color? = nil

    var body: some View {
        HStack {
            Text(label)
                .font(AppTypography.bodySmall)
                .foregroundColor(AppColors.textSecondary)
            Spacer()
            if let badge = badgeValue, let color = badgeColor {
                Text(badge)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.15))
                    .cornerRadius(6)
            } else if let val = value {
                Text(val)
                    .font(AppTypography.bodySmall)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
    }
}

// MARK: - Safari View

import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - String HTML Extension

extension String {
    func strippingHTML() -> String {
        guard let data = self.data(using: .utf8) else { return self }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributedString.string
        }

        // Fallback: simple regex strip
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}
