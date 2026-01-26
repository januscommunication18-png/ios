import Foundation
import SwiftData
import Combine

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

    // Offline mode support
    var isOffline: Bool { !NetworkMonitor.shared.isConnected }
    private var modelContext: ModelContext?
    private var networkCancellable: AnyCancellable?

    init() {
        modelContext = OfflineDataContainer.shared.mainContext

        // Listen for network changes to refresh when back online
        networkCancellable = NotificationCenter.default.publisher(for: .networkStatusChanged)
            .sink { [weak self] notification in
                if let isConnected = notification.userInfo?["isConnected"] as? Bool, isConnected {
                    Task { @MainActor in
                        await self?.refreshAssets()
                    }
                }
            }
    }

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

        // Load from cache first for instant display
        loadAssetsFromCache()

        // If offline, don't try server
        guard !isOffline else {
            isLoading = false
            return
        }

        do {
            let response: AssetsResponse = try await APIClient.shared.request(.assets)
            assets = response.assets ?? []
            totalValue = response.totalValue ?? 0
            formattedTotalValue = response.formattedTotalValue ?? "$\(Int(totalValue))"
            // Cache to local storage
            cacheAssetsToLocal(assets: assets, totalValue: totalValue, formattedTotal: formattedTotalValue)
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

        // If offline, just load from cache
        guard !isOffline else {
            loadAssetsFromCache()
            isRefreshing = false
            return
        }

        do {
            let response: AssetsResponse = try await APIClient.shared.request(.assets)
            assets = response.assets ?? []
            totalValue = response.totalValue ?? 0
            formattedTotalValue = response.formattedTotalValue ?? "$0"
            cacheAssetsToLocal(assets: assets, totalValue: totalValue, formattedTotal: formattedTotalValue)
        } catch {
            // Silently fail on refresh
        }

        isRefreshing = false
    }

    @MainActor
    func loadAsset(id: Int) async {
        isLoading = selectedAsset == nil
        errorMessage = nil

        // Load from cache first
        loadAssetFromCache(id: id)

        // If offline, don't try server
        guard !isOffline else {
            isLoading = false
            return
        }

        do {
            let response: AssetDetailResponse = try await APIClient.shared.request(.asset(id: id))
            selectedAsset = response.asset
            assetFiles = response.files ?? []
            // Cache to local storage
            cacheAssetDetailToLocal(asset: response.asset)
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

        // Load from cache first, filtered by category
        loadAssetsFromCache(category: category)

        // If offline, don't try server
        guard !isOffline else {
            isLoading = false
            return
        }

        do {
            let response: [Asset] = try await APIClient.shared.request(.assetsByCategory(category: category))
            assets = response
            // Cache to local storage
            cacheAssetsToLocal(assets: assets, totalValue: nil, formattedTotal: nil)
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

    // MARK: - Cache Methods

    private func loadAssetsFromCache(category: String? = nil) {
        guard let context = modelContext else { return }

        do {
            let deletedStatus = SyncStatus.pendingDelete.rawValue
            let descriptor: FetchDescriptor<CachedAsset>
            if let category = category {
                descriptor = FetchDescriptor<CachedAsset>(
                    predicate: #Predicate<CachedAsset> { cached in
                        cached.assetCategory == category && cached.syncStatus != deletedStatus
                    },
                    sortBy: [SortDescriptor(\CachedAsset.name)]
                )
            } else {
                descriptor = FetchDescriptor<CachedAsset>(
                    predicate: #Predicate<CachedAsset> { cached in
                        cached.syncStatus != deletedStatus
                    },
                    sortBy: [SortDescriptor(\CachedAsset.name)]
                )
            }
            let cachedAssets = try context.fetch(descriptor)

            if assets.isEmpty {
                assets = cachedAssets.map { $0.toAsset() }
                // Calculate total from cached assets
                if totalValue == 0 {
                    totalValue = cachedAssets.reduce(0) { $0 + ($1.currentValue ?? 0) }
                    formattedTotalValue = "$\(Int(totalValue))"
                }
            }
        } catch {
            print("Failed to load assets from cache: \(error)")
        }
    }

    private func cacheAssetsToLocal(assets: [Asset], totalValue: Double?, formattedTotal: String?) {
        guard let context = modelContext else { return }

        do {
            for asset in assets {
                let assetId = asset.id
                let descriptor = FetchDescriptor<CachedAsset>(
                    predicate: #Predicate<CachedAsset> { cached in
                        cached.serverId == assetId
                    }
                )
                if let existingAsset = try context.fetch(descriptor).first {
                    existingAsset.update(from: asset)
                } else {
                    let cachedAsset = CachedAsset(from: asset)
                    context.insert(cachedAsset)
                }
            }

            try context.save()
        } catch {
            print("Failed to cache assets: \(error)")
        }
    }

    private func loadAssetFromCache(id: Int) {
        guard let context = modelContext else { return }

        do {
            let assetId = id
            let descriptor = FetchDescriptor<CachedAsset>(
                predicate: #Predicate<CachedAsset> { cached in
                    cached.serverId == assetId
                }
            )
            if let cachedAsset = try context.fetch(descriptor).first {
                selectedAsset = cachedAsset.toAsset()
                // Note: Files are not cached in this implementation
                // You may want to add CachedAssetFile model for full offline support
            }
        } catch {
            print("Failed to load asset from cache: \(error)")
        }
    }

    private func cacheAssetDetailToLocal(asset: Asset) {
        guard let context = modelContext else { return }

        do {
            let assetId = asset.id
            let descriptor = FetchDescriptor<CachedAsset>(
                predicate: #Predicate<CachedAsset> { cached in
                    cached.serverId == assetId
                }
            )
            if let existingAsset = try context.fetch(descriptor).first {
                existingAsset.update(from: asset)
            } else {
                let cachedAsset = CachedAsset(from: asset)
                context.insert(cachedAsset)
            }

            try context.save()
        } catch {
            print("Failed to cache asset detail: \(error)")
        }
    }
}
