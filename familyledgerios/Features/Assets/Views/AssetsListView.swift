import SwiftUI

struct AssetsListView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = AssetsViewModel()
    @State private var searchText = ""
    @State private var selectedCategory: String?

    var filteredAssets: [Asset] {
        var result = viewModel.assets

        if let category = selectedCategory {
            result = result.filter { $0.assetCategory == category }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                ($0.assetType?.lowercased().contains(query) == true)
            }
        }

        return result
    }

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            Group {
                if viewModel.isLoading {
                    LoadingView(message: "Loading assets...")
                } else if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        Task { await viewModel.loadAssets() }
                    }
                } else {
                    assetsContent
                }
            }
            .navigationTitle("Assets")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refreshAssets()
            }
            .task {
                await viewModel.loadAssets()
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .asset(let id):
                    AssetDetailView(assetId: id)
                default:
                    EmptyView()
                }
            }
        }
        .environment(router)
    }

    private var assetsContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Total Value Card
                totalValueCard

                // Search & Filter
                VStack(spacing: 12) {
                    SearchBar(text: $searchText, placeholder: "Search assets...")

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(
                                title: "All",
                                isSelected: selectedCategory == nil
                            ) {
                                selectedCategory = nil
                            }

                            ForEach(["property", "vehicle", "valuable", "inventory"], id: \.self) { category in
                                FilterChip(
                                    title: formatCategoryName(category),
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                }

                // Assets List
                if filteredAssets.isEmpty {
                    EmptyStateView(
                        icon: "dollarsign.circle",
                        title: "No Assets",
                        message: "Start tracking your assets by adding them here."
                    )
                    .frame(minHeight: 200)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredAssets) { asset in
                            AssetCard(asset: asset) {
                                router.navigate(to: .asset(id: asset.id))
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private var totalValueCard: some View {
        VStack(spacing: 8) {
            Text("Total Asset Value")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            Text(viewModel.formattedTotalValue)
                .font(AppTypography.displayMedium)
                .foregroundColor(AppColors.textPrimary)

            Text("\(viewModel.assets.count) assets")
                .font(AppTypography.captionSmall)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    private func formatCategoryName(_ category: String) -> String {
        category.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - Asset Card

struct AssetCard: View {
    let asset: Asset
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Asset Image or Category Icon
                if let imageUrl = asset.imageUrl, !imageUrl.isEmpty {
                    AsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            categoryIconView
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        case .failure:
                            categoryIconView
                        @unknown default:
                            categoryIconView
                        }
                    }
                    .frame(width: 56, height: 56)
                } else {
                    categoryIconView
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(asset.name)
                        .font(AppTypography.headline)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(asset.assetType ?? "Asset")
                            .font(AppTypography.captionSmall)
                            .foregroundColor(AppColors.textSecondary)

                        Badge(text: formatStatusName(asset.status), color: colorForStatus(asset.status))
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(asset.formattedCurrentValue ?? "$0")
                        .font(AppTypography.numberSmall)
                        .foregroundColor(AppColors.textPrimary)

                    if asset.isInsured == true {
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.success)
                    }
                }
            }
            .padding()
            .background(AppColors.background)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private var categoryIconView: some View {
        Image(systemName: iconForCategory(asset.assetCategory))
            .font(.system(size: 20))
            .foregroundColor(.white)
            .frame(width: 56, height: 56)
            .background(colorForCategory(asset.assetCategory))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func iconForCategory(_ category: String?) -> String {
        switch category {
        case "real_estate": return "house.fill"
        case "vehicle": return "car.fill"
        case "investment": return "chart.line.uptrend.xyaxis"
        case "valuable": return "diamond.fill"
        default: return "cube.fill"
        }
    }

    private func colorForCategory(_ category: String?) -> Color {
        switch category {
        case "real_estate": return .blue
        case "vehicle": return .green
        case "investment": return .purple
        case "valuable": return .orange
        default: return .gray
        }
    }

    private func formatStatusName(_ status: String?) -> String {
        (status ?? "active").replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func colorForStatus(_ status: String?) -> Color {
        switch status {
        case "active": return AppColors.success
        case "sold", "disposed": return AppColors.error
        case "maintenance": return AppColors.warning
        default: return AppColors.textSecondary
        }
    }
}

// MARK: - Asset Detail View

struct AssetDetailView: View {
    let assetId: Int

    @State private var viewModel = AssetsViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading asset...")
            } else if let asset = viewModel.selectedAsset {
                assetContent(asset: asset)
            } else if let error = viewModel.errorMessage {
                ErrorView(message: error) {
                    Task {
                        await viewModel.loadAsset(id: assetId)
                    }
                }
            } else {
                LoadingView(message: "Loading asset...")
            }
        }
        .navigationTitle("Asset Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadAsset(id: assetId)
        }
    }

    private func assetContent(asset: Asset) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Asset Name Header
                assetNameSection(asset: asset)

                // Basic Info Section
                basicInfoSection(asset: asset)

                // Description Section
                if let description = asset.description, !description.isEmpty {
                    descriptionSection(description: description)
                }

                // Vehicle Details Section (if vehicle)
                if asset.assetCategory == "vehicle" {
                    vehicleDetailsSection(asset: asset)
                }

                // Value Section
                valueSection(asset: asset)

                // Location Section
                if asset.locationAddress != nil || asset.storageLocation != nil || asset.roomLocation != nil {
                    locationSection(asset: asset)
                }

                // Ownership Section
                ownershipSection(asset: asset)

                // Insurance Section
                insuranceSection(asset: asset)

                // Owners Section
                if let owners = asset.owners, !owners.isEmpty {
                    ownersSection(owners: owners)
                }

                // Documents Section
                documentsSection(asset: asset)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func assetNameSection(asset: Asset) -> some View {
        VStack(spacing: 16) {
            // Show image if available, otherwise show icon
            if let imageUrl = asset.imageUrl, !imageUrl.isEmpty {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        assetIconPlaceholder(asset: asset)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    case .failure:
                        assetIconPlaceholder(asset: asset)
                    @unknown default:
                        assetIconPlaceholder(asset: asset)
                    }
                }
            } else {
                assetIconPlaceholder(asset: asset)
            }

            Text("Asset Name")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            Text(asset.name)
                .font(AppTypography.displaySmall)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }

    private func assetIconPlaceholder(asset: Asset) -> some View {
        Image(systemName: iconForCategory(asset.assetCategory))
            .font(.system(size: 40))
            .foregroundColor(.white)
            .frame(width: 80, height: 80)
            .background(colorForCategory(asset.assetCategory))
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func basicInfoSection(asset: Asset) -> some View {
        VStack(spacing: 0) {
            DetailRow(label: "Category", value: formatCategoryName(asset.assetCategory))
            Divider()
            DetailRow(label: "Type", value: asset.assetType ?? "N/A")
            Divider()
            HStack {
                Text("Status")
                    .font(AppTypography.bodyMedium)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                Badge(text: formatStatusName(asset.status), color: colorForStatus(asset.status))
            }
            .padding()
            Divider()
            DetailRow(label: "Acquisition Date", value: formatDate(asset.acquisitionDate))
        }
        .background(AppColors.background)
        .cornerRadius(12)
    }

    private func descriptionSection(description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(AppTypography.headline)
                .foregroundColor(AppColors.textPrimary)

            Text(description)
                .font(AppTypography.bodyMedium)
                .foregroundColor(AppColors.textSecondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.background)
                .cornerRadius(12)
        }
    }

    private func vehicleDetailsSection(asset: Asset) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "car.fill")
                    .foregroundColor(AppColors.primary)
                Text("Vehicle Details")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }

            Text("Vehicle-specific information")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            // Vehicle Title (Year Make Model)
            if let year = asset.vehicleYear, let make = asset.vehicleMake, let model = asset.vehicleModel {
                Text("\(year) \(make) \(model)")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.primary.opacity(0.1))
                    .cornerRadius(8)
            }

            VStack(spacing: 0) {
                if let make = asset.vehicleMake {
                    DetailRow(label: "Make", value: make)
                    Divider()
                }
                if let model = asset.vehicleModel {
                    DetailRow(label: "Model", value: model)
                    Divider()
                }
                if let year = asset.vehicleYear {
                    DetailRow(label: "Year", value: "\(year)")
                    Divider()
                }
                if let vin = asset.vinRegistration {
                    DetailRow(label: "VIN / Registration", value: vin)
                    Divider()
                }
                if let plate = asset.licensePlate {
                    DetailRow(label: "License Plate", value: plate)
                    Divider()
                }
                if let mileage = asset.mileage {
                    DetailRow(label: "Mileage", value: formatNumber(mileage) + " miles")
                }
            }
            .background(AppColors.background)
            .cornerRadius(12)
        }
    }

    private func valueSection(asset: Asset) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(AppColors.success)
                Text("Value")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }

            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    Text(asset.formattedCurrentValue ?? "$0")
                        .font(AppTypography.numberMedium)
                        .foregroundColor(AppColors.success)

                    Text("Current Value")
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.success.opacity(0.1))
                .cornerRadius(12)

                VStack(spacing: 4) {
                    Text(formatCurrency(asset.purchaseValue))
                        .font(AppTypography.numberMedium)
                        .foregroundColor(AppColors.textPrimary)

                    Text("Purchase Value")
                        .font(AppTypography.captionSmall)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.secondaryBackground)
                .cornerRadius(12)
            }

            VStack(spacing: 0) {
                DetailRow(label: "Currency", value: asset.currency ?? "USD")
            }
            .background(AppColors.background)
            .cornerRadius(12)
        }
    }

    private func locationSection(asset: Asset) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(AppColors.primary)
                Text("Location")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }

            VStack(spacing: 0) {
                if let address = asset.locationAddress {
                    DetailRow(label: "Address", value: address)
                    Divider()
                }
                if let city = asset.locationCity {
                    DetailRow(label: "City", value: city)
                    Divider()
                }
                if let state = asset.locationState {
                    DetailRow(label: "State", value: state)
                    Divider()
                }
                if let country = asset.locationCountry {
                    DetailRow(label: "Country", value: country)
                    Divider()
                }
                if let storage = asset.storageLocation {
                    DetailRow(label: "Storage Location", value: storage)
                    Divider()
                }
                if let room = asset.roomLocation {
                    DetailRow(label: "Room", value: room)
                }
            }
            .background(AppColors.background)
            .cornerRadius(12)
        }
    }

    private func ownershipSection(asset: Asset) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundColor(AppColors.primary)
                Text("Ownership Status")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }

            VStack(spacing: 0) {
                DetailRow(label: "Ownership Type", value: formatOwnershipType(asset.ownershipType))
            }
            .background(AppColors.background)
            .cornerRadius(12)
        }
    }

    private func insuranceSection(asset: Asset) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.checkered")
                    .foregroundColor(asset.isInsured == true ? AppColors.success : AppColors.textSecondary)
                Text("Insurance Information")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }

            Text("Insurance coverage details")
                .font(AppTypography.caption)
                .foregroundColor(AppColors.textSecondary)

            VStack(spacing: 0) {
                HStack {
                    Text("Insured")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text(asset.isInsured == true ? "Yes" : "No")
                        .font(AppTypography.bodyMedium)
                        .foregroundColor(asset.isInsured == true ? AppColors.success : AppColors.error)
                }
                .padding()

                if asset.isInsured == true {
                    Divider()
                    if let provider = asset.insuranceProvider {
                        DetailRow(label: "Provider", value: provider)
                        Divider()
                    }
                    if let policy = asset.insurancePolicyNumber {
                        DetailRow(label: "Policy Number", value: policy)
                        Divider()
                    }
                    if let renewal = asset.insuranceRenewalDate {
                        DetailRow(label: "Renewal Date", value: formatDate(renewal))
                    }
                }
            }
            .background(AppColors.background)
            .cornerRadius(12)
        }
    }

    private func ownersSection(owners: [AssetOwner]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(AppColors.primary)
                Text("Owners")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)
            }

            VStack(spacing: 8) {
                ForEach(owners) { owner in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(owner.ownerName ?? "Unknown")
                                .font(AppTypography.bodyMedium)
                                .foregroundColor(AppColors.textPrimary)

                            if owner.isPrimaryOwner == true {
                                Text("Primary Owner")
                                    .font(AppTypography.captionSmall)
                                    .foregroundColor(AppColors.primary)
                            }
                        }

                        Spacer()

                        if let percentage = owner.ownershipPercentage {
                            Text("\(Int(percentage))%")
                                .font(AppTypography.numberSmall)
                                .foregroundColor(AppColors.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppColors.primary.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(12)
                }
            }
        }
    }

    private func documentsSection(asset: Asset) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundColor(AppColors.primary)
                Text("Documents & Photos")
                    .font(AppTypography.headline)
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Text("\(viewModel.assetFiles.count) file\(viewModel.assetFiles.count == 1 ? "" : "s")")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            if !viewModel.assetFiles.isEmpty {
                VStack(spacing: 8) {
                    ForEach(viewModel.assetFiles) { file in
                        AssetFileRow(file: file)
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
                .background(AppColors.background)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Helper Functions

    private func iconForCategory(_ category: String?) -> String {
        switch category {
        case "real_estate": return "house.fill"
        case "vehicle": return "car.fill"
        case "investment": return "chart.line.uptrend.xyaxis"
        case "valuable": return "diamond.fill"
        default: return "cube.fill"
        }
    }

    private func colorForCategory(_ category: String?) -> Color {
        switch category {
        case "real_estate": return .blue
        case "vehicle": return .green
        case "investment": return .purple
        case "valuable": return .orange
        default: return .gray
        }
    }

    private func formatStatusName(_ status: String?) -> String {
        (status ?? "active").replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func colorForStatus(_ status: String?) -> Color {
        switch status {
        case "active": return AppColors.success
        case "sold", "disposed": return AppColors.error
        case "maintenance": return AppColors.warning
        default: return AppColors.textSecondary
        }
    }

    private func formatCategoryName(_ category: String?) -> String {
        (category ?? "other").replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func formatCurrency(_ value: Double?) -> String {
        guard let value = value else { return "$0" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }

    private func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "N/A" }

        // Try to parse ISO date
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = isoFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .long
            return displayFormatter.string(from: date)
        }

        // Try simpler ISO format
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .long
            return displayFormatter.string(from: date)
        }

        // Return original if parsing fails
        return dateString
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    private func formatOwnershipType(_ type: String?) -> String {
        guard let type = type else { return "N/A" }
        return type.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

// MARK: - Asset File Row

struct AssetFileRow: View {
    let file: AssetFile
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

                    HStack(spacing: 8) {
                        if let typeName = file.documentTypeName {
                            Text(typeName)
                                .font(AppTypography.captionSmall)
                                .foregroundColor(AppColors.textTertiary)
                        }

                        if let size = file.formattedSize {
                            Text(size)
                                .font(AppTypography.captionSmall)
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                }

                Spacer()

                // View indicator
                Image(systemName: file.isImage == true ? "arrow.up.left.and.arrow.down.right" : "eye")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(12)
            .background(AppColors.background)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showImageViewer) {
            if let viewUrl = file.viewUrl {
                AssetImageViewerSheet(imageUrl: viewUrl, fileName: file.name)
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

// MARK: - Asset Image Viewer Sheet

struct AssetImageViewerSheet: View {
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

#Preview {
    AssetsListView()
}
