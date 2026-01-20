import Foundation

@Observable
final class AssetsViewModel {
    var assets: [Asset] = []
    var totalValue: Double = 0
    var formattedTotalValue: String = "$0"
    var selectedAsset: Asset?
    var assetFiles: [AssetFile] = []

    var isLoading = false
    var isRefreshing = false
    var errorMessage: String?

    // MARK: - Computed Properties

    var hasAssets: Bool {
        !assets.isEmpty
    }

    var assetsByCategory: [String: [Asset]] {
        Dictionary(grouping: assets, by: { $0.assetCategory ?? "other" })
    }

    // MARK: - API Methods

    @MainActor
    func loadAssets() async {
        isLoading = assets.isEmpty
        errorMessage = nil

        do {
            let response: AssetsResponse = try await APIClient.shared.request(.assets)
            assets = response.assets ?? []
            totalValue = response.totalValue ?? 0
            formattedTotalValue = response.formattedTotalValue ?? "$\(Int(totalValue))"
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to load assets: \(error.localizedDescription)"
        }

        isLoading = false
    }

    @MainActor
    func refreshAssets() async {
        isRefreshing = true

        do {
            let response: AssetsResponse = try await APIClient.shared.request(.assets)
            assets = response.assets ?? []
            totalValue = response.totalValue ?? 0
            formattedTotalValue = response.formattedTotalValue ?? "$0"
        } catch {
            // Silently fail on refresh
        }

        isRefreshing = false
    }

    @MainActor
    func loadAsset(id: Int) async {
        isLoading = selectedAsset == nil
        errorMessage = nil

        do {
            let response: AssetDetailResponse = try await APIClient.shared.request(.asset(id: id))
            selectedAsset = response.asset
            assetFiles = response.files ?? []
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to load asset details"
        }

        isLoading = false
    }

    @MainActor
    func loadAssetsByCategory(category: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response: [Asset] = try await APIClient.shared.request(.assetsByCategory(category: category))
            assets = response
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to load assets"
        }

        isLoading = false
    }

    // MARK: - Filtering

    func filterAssets(by category: String?) -> [Asset] {
        guard let category = category else { return assets }
        return assets.filter { $0.assetCategory == category }
    }

    func filterAssetsByStatus(_ status: String?) -> [Asset] {
        guard let status = status else { return assets }
        return assets.filter { $0.status == status }
    }

    func searchAssets(query: String) -> [Asset] {
        guard !query.isEmpty else { return assets }
        let lowercasedQuery = query.lowercased()
        return assets.filter {
            $0.name.lowercased().contains(lowercasedQuery) ||
            ($0.assetType?.lowercased().contains(lowercasedQuery) == true) ||
            ($0.description?.lowercased().contains(lowercasedQuery) == true)
        }
    }
}
