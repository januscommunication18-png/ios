import Foundation
import Network

@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    private(set) var isConnected: Bool = true
    private(set) var connectionType: ConnectionType = .unknown

    // DEBUG: Toggle to simulate offline mode in simulator
    #if DEBUG
    var simulateOffline: Bool = false {
        didSet {
            updateConnectionStatus()
        }
    }
    private var actualConnectionStatus: Bool = true
    #endif

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")

    enum ConnectionType {
        case wifi
        case cellular
        case wiredEthernet
        case unknown
    }

    private init() {
        monitor = NWPathMonitor()
    }

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                #if DEBUG
                self?.actualConnectionStatus = path.status == .satisfied
                self?.updateConnectionStatus()
                #else
                self?.isConnected = path.status == .satisfied
                NotificationCenter.default.post(
                    name: .networkStatusChanged,
                    object: nil,
                    userInfo: ["isConnected": path.status == .satisfied]
                )
                #endif
                self?.connectionType = self?.getConnectionType(path) ?? .unknown
            }
        }
        monitor.start(queue: queue)
    }

    #if DEBUG
    private func updateConnectionStatus() {
        let effectiveStatus = simulateOffline ? false : actualConnectionStatus
        if isConnected != effectiveStatus {
            isConnected = effectiveStatus
            NotificationCenter.default.post(
                name: .networkStatusChanged,
                object: nil,
                userInfo: ["isConnected": effectiveStatus]
            )
        }
    }
    #endif

    func stop() {
        monitor.cancel()
    }

    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wiredEthernet
        }
        return .unknown
    }
}

// MARK: - Notification Name
extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
    static let syncCompleted = Notification.Name("syncCompleted")
    static let syncFailed = Notification.Name("syncFailed")
    static let conflictDetected = Notification.Name("conflictDetected")
}
