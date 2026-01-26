import SwiftUI

#if DEBUG
struct OfflineDebugView: View {
    @State private var isOffline = NetworkMonitor.shared.simulateOffline

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isOffline ? "wifi.slash" : "wifi")
                .foregroundColor(isOffline ? .red : .green)
                .font(.system(size: 14))

            Text(isOffline ? "Offline" : "Online")
                .font(.caption)
                .foregroundColor(isOffline ? .red : .green)

            Toggle("", isOn: $isOffline)
                .labelsHidden()
                .scaleEffect(0.8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
        .onChange(of: isOffline) { _, newValue in
            NetworkMonitor.shared.simulateOffline = newValue
        }
    }
}

/// Overlay modifier to show debug controls
struct OfflineDebugOverlay: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                OfflineDebugView()
                    .padding(.top, 50)
                    .padding(.trailing, 16)
            }
    }
}

extension View {
    /// Adds offline debug toggle overlay (DEBUG builds only)
    func offlineDebugOverlay() -> some View {
        modifier(OfflineDebugOverlay())
    }
}

#Preview {
    VStack {
        Text("App Content")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .offlineDebugOverlay()
}
#endif
